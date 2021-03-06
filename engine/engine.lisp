(cl:in-package :cl-bodge.engine)

(defvar *engine* nil)

(defvar *engine-startup-hooks* nil)
(defvar *system-startup-hooks* (mt:make-guarded-reference (make-hash-table)))
(defvar *system-shutdown-hooks* (mt:make-guarded-reference (make-hash-table)))
(defvar *predefined-event-callbacks* nil)
(defvar *executable-p* nil)

(declaim (special *system*))


(define-constant +engine-resource-path+ "/bodge/"
  :test #'equal)

;;
(defclass bodge-engine (disposable lockable)
  ((systems :initform nil)
   (event-emitter :initform nil :reader event-emitter-of)
   (properties :initform '())
   (working-directory :initform nil :reader working-directory-of)
   (shared-executors :initform nil)
   (shared-pool :initform nil)
   (comatose-p :initform nil)
   (stop-latch :initform (mt:make-latch) :reader %stop-latch-of)
   (disabling-order :initform '())
   (scheduler :initform nil)))


(definline engine ()
  "Return engine instance"
  *engine*)


(defun engine-system (system-name &optional (error-if-not-exist t))
  "Return engine's system instance by class name. Throws error if system cannot be found."
  (if-let ((engine (engine)))
    (when-let (system-map (slot-value engine 'systems))
      (if-let ((system (gethash system-name system-map)))
        system
        (when error-if-not-exist
          (error (format nil "~a engine system not found" system-name)))))
    (warn "Engine offline: system cannot be retrieved")))


(defun after-system-startup (system-name hook)
  (mt:with-guarded-reference (hooks *system-startup-hooks*)
    (push hook (gethash system-name hooks))))


(defun invoke-system-startup-hooks (system-name)
  (mt:with-guarded-reference (hooks *system-startup-hooks*)
    (log-errors
      (dolist (hook (gethash system-name hooks))
        (funcall hook)))))


(defun before-system-shutdown (system-name hook)
  (mt:with-guarded-reference (hooks *system-shutdown-hooks*)
    (push hook (gethash system-name hooks))))


(defun invoke-system-shutdown-hooks (system-name)
  (mt:with-guarded-reference (hooks *system-shutdown-hooks*)
    (log-errors
      (dolist (hook (gethash system-name hooks))
        (funcall hook)))))


(defun working-directory ()
  "Return working directory of the engine which corresponds to the directory where configuration
file is stored."
  (working-directory-of (engine)))


(defun merge-working-pathname (pathname)
  "Merge `pathname` with engine's working directory."
  (merge-pathnames pathname (working-directory)))


(defun executablep ()
  (or *executable-p* uiop:*image-dumped-p*))


(defmacro instantly ((&rest lambda-list) &body body)
  "Execute task in the current thread without dispatching."
  `(-> nil ,lambda-list
     ,@body))


(defmacro concurrently ((&rest lambda-list) &body body)
  "Push task to engine's pooled executor."
  `(-> nil :concurrently t ,lambda-list
     ,@body))


(defun value-flow (value)
  "Return flow that returns a single value."
  (instantly () value))


(defun null-flow ()
  "Return flow that returns nil as a single value."
  (value-flow nil))


(defun always-true () t)


(defun loop-flow (flow &optional (test #'always-true))
  "Turns passed flow into a loop. Flow will be repeated while test function returns `t`.
Test happens before each flow execution. Result of the last flow iteration is passed to the next
flow block after the looped flow."
  (flow:repeatedly (funcall test) flow))

;;
(defclass system ()
  ((dependencies :initarg :depends-on :initform '() :reader dependencies-of))
  (:documentation "Base class for all engine systems"))


(defgeneric enabling-flow (system)
  (:method list (system) nil)
  (:method-combination list :most-specific-last)
  (:documentation "Enable engine's system asynchronously."))


(defgeneric disabling-flow (system)
  (:method list (system) nil)
  (:method-combination list :most-specific-first)
  (:documentation "Disable engine's system asynchronously."))


(defgeneric enabledp (system)
  (:documentation "Check if `system` is enabled. Must be thread-safe."))


;;
(defun instantiate-systems (system-class-names &optional sys-alist)
  (loop for class-name in system-class-names
        with result = sys-alist
        unless (assoc class-name result)
          do (let ((system (make-instance (find-class class-name))))
               (setf result
                     (instantiate-systems (dependencies-of system)
                                          (acons class-name system result))))
        finally (return result)))


(defun enable-system (system-class sys-alist sys-table &optional order)
  (flet ((system-enabled-p (system-class)
           (assoc-value order system-class)))
    (let ((system (assoc-value sys-alist system-class))
          (result order))
      (if (not (system-enabled-p system-class))
          (progn
            (dolist (dependency (dependencies-of system))
              (setf result (enable-system dependency sys-alist sys-table result)))
            (when (system-enabled-p system)
              (error (format nil "Circular dependency found for '~a'" system-class)))
            (cons (cons system-class (>> (instantly ()
                                           (log/debug "Enabling ~a" system-class))
                                         (enabling-flow system)
                                         (instantly ()
                                           (setf (gethash system-class sys-table) system)
                                           (invoke-system-startup-hooks system-class))))
                  result))
          result))))


(defun requested-systems-enabling-flow (sys-alist sys-table)
  (loop for (system-class) in sys-alist
        with order = (list) do
          (setf order (enable-system system-class sys-alist sys-table order))
        finally (return (nreverse order))))


(defun property (key &optional (default-value nil))
  "Return engine's property provided in the configuration file or `default-value` if it was not
specified."
  (with-slots (properties) *engine*
    (%get-property key properties default-value)))


(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *unloaded-foreign-libraries* nil)

  (defun unload-foreign-libraries ()
    (shout "Closing foreign libraries")
    (bodge-blobs-support:close-foreign-libraries)
    (handler-bind ((style-warning #'muffle-warning))
      (loop for lib in (cffi:list-foreign-libraries)
            when (cffi:foreign-library-loaded-p lib)
              do (progn
                   (pushnew (cffi:foreign-library-name lib) *unloaded-foreign-libraries*)
                   (cffi:close-foreign-library lib)))))


  (defun reload-foreign-libraries (library-directory)
    (bodge-blobs-support:register-library-directory (merge-working-pathname library-directory))
    (bodge-blobs-support:load-foreign-libraries)
    (loop for lib-name in *unloaded-foreign-libraries*
          do (cffi:load-foreign-library lib-name)))


  (defun mark-executable ()
    (setf *executable-p* t))

  (dolist (hook (list #'unload-foreign-libraries #'mark-executable))
    (uiop:register-image-dump-hook hook)))


(defun enable-systems (engine)
  (with-slots (systems disabling-order) engine
    (let ((system-class-names (property '(:engine :systems))))
      (when (null system-class-names)
        (warn "(:engine :systems) property is empty. No systems are going to be enabled."))
      (let* ((sys-table (make-hash-table))
             (sys-alist (instantiate-systems system-class-names))
             (enabling-flows (requested-systems-enabling-flow sys-alist sys-table)))
        (setf systems sys-table
              disabling-order (reverse (mapcar #'car enabling-flows)))
        (mt:wait-with-latch (latch)
          (run (>> (mapcar #'cdr enabling-flows)
                   (instantly ()
                     (mt:open-latch latch)))))))))


(defun disable-systems (engine)
  (with-slots (systems disabling-order comatose-p) engine
    (setf comatose-p t)
    (mt:wait-with-latch (latch)
      (run (>> (loop for system-class in disabling-order
                     collect (let ((system-class system-class))
                               (>> (instantly ()
                                     (log/debug "Disabling ~a" system-class)
                                     (invoke-system-shutdown-hooks system-class))
                                   (when-let ((system (gethash system-class systems)))
                                     (disabling-flow system)))))
               (instantly ()
                 (mt:open-latch latch)))))))


(defmethod initialize-instance :after ((this bodge-engine)
                                       &key properties working-directory)
  (with-slots (systems (this-properties properties)
               (this-working-directory working-directory)
               shared-pool shared-executors event-emitter
               scheduler)
      this
    (setf this-properties (%load-properties properties)
          shared-pool (make-pooled-executor
                       (%get-property '(:engine :shared-pool-size) this-properties 2))
          this-working-directory working-directory
          shared-executors (list (make-single-threaded-executor))
          event-emitter (make-instance 'event-emitting)
          scheduler (muth:start-scheduler (muth:make-scheduler)))
    (loop for (event-class-name . handlers) in *predefined-event-callbacks*
          do (dolist (handler handlers)
               (ge.eve:subscribe-to event-class-name event-emitter handler)))))


(define-destructor bodge-engine (shared-pool shared-executors scheduler)
  (dispose shared-pool)
  (dolist (ex shared-executors)
    (dispose ex))
    (muth:stop-scheduler scheduler))


(defun startup (properties &key (working-directory (directory-namestring
                                                    (current-executable-path)))
                             blocking)
  "Start engine synchronously loading configuration from `properties` (file, hash-table, plist
or alist). `(:engine :systems)` property must exist in the config and should contain list
of existing system class names loaded into current lisp image. Specified systems and their
dependencies will be initialized in the correct order according to a dependency graph. All
directories used by the engine are relative to 'working-directory parameter."
  (when *engine*
    (error "Engine already running"))
  (setf *engine* (make-instance 'bodge-engine
                                :properties properties
                                :working-directory working-directory))
  (log/level (property '(:engine :log-level) :info))
  (reload-foreign-libraries (property '(:engine :library-directory) "lib/"))
  (log-errors
    (dolist (hook *engine-startup-hooks*)
      (funcall hook)))
  (in-new-thread-waiting ("startup-worker")
    (enable-systems *engine*))
  (when blocking
    (mt:wait-for-latch (%stop-latch-of *engine*)))
  (values))


(defun shutdown ()
  "Shutdown engine synchronously and deinitialize systems in the reverse order they were
initialized."
  (unless *engine*
    (error "Engine already stopped"))
  (in-new-thread-waiting ("shutdown-worker")
    (disable-systems *engine*))
  (let ((latch (%stop-latch-of *engine*)))
    (dispose *engine*)
    (setf *engine* nil)
    (mt:open-latch latch))
  (values))


(defun acquire-executor (&rest args &key (single-threaded-p nil) (exclusive-p nil)
                                      (special-variables nil)
                                      (invoker nil))
  "Acquire executor from the engine, properties of which correspond to provided options:
:single-threaded-p - if t, executor will be single-threaded, otherwise it can be pooled one
:exclusive-p - if t, this executor cannot be acquired by other requester and :special-variables
               can be specified for it, otherwise this executor could be shared among different
               requesters."
  (with-slots (shared-pool shared-executors) *engine*
    (cond
      ((and (not exclusive-p)
            (not single-threaded-p)
            (not special-variables)
            (not invoker))
       shared-pool)
      ((and exclusive-p single-threaded-p)
       (make-single-threaded-executor :special-variables special-variables
                                      :invoker invoker))
      ((and single-threaded-p
            (not exclusive-p)
            (not special-variables)
            (not invoker))
       (first shared-executors))
      (t (error "Cannot provide executor for combination of requirements: ~a" args)))))


(defun shared-executor-p (executor shared-executors)
  (some (lambda (shared) (eq shared executor)) shared-executors))


(defun release-executor (executor)
  "Release executor back to the engine"
  (with-slots (shared-pool shared-executors) *engine*
    (unless (or (shared-executor-p executor shared-executors)
                (eq executor shared-pool))
      (dispose executor))))


(defclass dispatching () ()
  (:documentation "Mixin class for all engine dispatchers"))


(defmethod dispatch ((this null) (task function) invariant &rest keys &key)
  (log/error "~A with invariant ~A and keys ~A ignored" task invariant keys))


(definline invoke-safely (engine task)
  (with-slots (comatose-p) engine
    (block ignorable
      (flet ((handle-comatose (e)
               (when comatose-p
                 (log/error "Error encountered while engine is in coma, ignoring: ~A" e)
                 (when-let ((continue-handler (find-restart 'continue)))
                   (invoke-restart continue-handler))))
             (handle-continue ()
               (if (find-restart 'flow:skip-flow-block)
                   (flow:skip-flow-block)
                   (return-from ignorable)))
             (report-continue (stream)
               (format stream "Ignore error by skipping current flow block"))
             (handle-abort ()
               (log/debug "Abort restart invoked. Trying to shutdown engine gracefully")
               (if (find-restart 'flow:inject-flow)
                   (flow:inject-flow (>> (instantly () (setf comatose-p t))
                                         (concurrently () (shutdown))))
                   (return-from ignorable)))
             (report-abort (stream)
               (format stream "Shutdown cl-bodge engine")))
        (handler-bind ((t #'handle-comatose))
          (restart-bind ((continue #'handle-continue :report-function #'report-continue)
                         (abort #'handle-abort :report-function #'report-abort))
            (float-features:with-float-traps-masked t
              (funcall task))))))))


(defmethod dispatch ((this bodge-engine) (task function) invariant &rest keys
                     &key (priority :medium) concurrently)
  "Use engine instance as a dispatcher. If :invariant and :concurrently-p are both nil task is
not dispatched and just executed in the current thread. If :invariant is nil but :concurrently-p
is t, task is dispatched to the engine's default pooled executor. If :invariant is specified,
task is dispatched to the object provided under this key."
  (with-slots (shared-pool) this
    (labels ((traps-masking-task ()
               (invoke-safely this task)))
      (etypecase invariant
        (null (if concurrently
                  (execute shared-pool #'traps-masking-task :priority priority)
                  (traps-masking-task)))
        (symbol (execute shared-pool #'traps-masking-task :invariant invariant :priority priority))
        (dispatching (apply #'dispatch invariant #'traps-masking-task nil keys)))
      t)))


(defgeneric initialization-flow (object &key &allow-other-keys)
  (:documentation "Return flow that initializes an object.
Flow variant of #'initialize-instance, although no guarantees
about object returned from the flow are provided.")
  (:method-combination list)
  (:method list (object &key &allow-other-keys)))


(defmethod initialization-flow :around (object &key &allow-other-keys)
  (>> (call-next-method)
      (instantly ()
        (initialize-destructor object))))


(defun assembly-flow (class &rest initargs &key &allow-other-keys)
  "Return flow that constructs an object and returns it.
Flow variant of #'make-instance."
  (let* ((*auto-initialize-destructor* nil)
         (instance (apply #'make-instance class :allow-other-keys t initargs)))
    (>> (apply #'initialization-flow instance initargs)
        (value-flow instance))))


(flet ((%dispatch (task invariant &rest opts &key &allow-other-keys)
         (apply #'dispatch (engine) task invariant opts)))
  (defun run (flow)
    "Dispatch flow using engine as a dispatcher."
    (flow:run #'%dispatch flow)))


(defun schedule (flow &key (wait 0) interval unschedule-test)
  (with-slots (scheduler) (engine)
    (flet ((%run ()
             (if (and unschedule-test (funcall unschedule-test))
                 (muth:unschedule)
                 (run flow))))
      (muth:schedule scheduler #'%run wait interval))))

;;
(defgeneric system-of (obj)
  (:documentation "Return system obj has relation with."))


(defclass system-object ()
  (system)
  (:documentation "Base class for objects that has any relationship with particular system."))


(defmethod system-of ((this system-object))
  "Return system this object has relationship with."
  (with-slots (system) this
    (tg:weak-pointer-value system)))


(defmethod initialize-instance :after ((this system-object) &key system)
  (with-slots ((this-system system)) this
    (setf this-system (tg:make-weak-pointer (ensure-not-null (or system *system*))))))


;;;
;;;
;;;
(defclass enableable ()
  ((enabled-p :initform nil))
  (:documentation "Mixin for systems for making them enableable: conform to
 enabledp/enabling-flow/disabling-flow interface."))


(defmethod enabledp ((this enableable))
  (with-slots (enabled-p) this
    enabled-p))


(defmethod enabling-flow list ((this enableable))
  (with-slots (enabled-p) this
    (instantly ()
      (setf enabled-p t))))


(defmethod disabling-flow list ((this enableable))
  (with-slots (enabled-p) this
    (instantly ()
      (setf enabled-p nil))))


;;;
;;;
;;;
(defmacro define-system-function (name system-class lambda-list &body body)
  "Define function that bound to the system, i.e. its body must be executed only when *system*
special variable corresponds to the instance of the `system-class`."
  (multiple-value-bind (forms decls doc) (parse-body body :documentation t)
    `(defun ,name ,lambda-list
       ,@(when doc (list doc))
       ,@decls
       (in-development-mode
         (cond
           ((or (not (boundp '*system*)) (null *system*))
            (error (concatenate 'string "~a executed in the wrong system thread:"
                                " *system* unbound or nil, but ~a required")
                   ',name ',system-class))
           ((not (subtypep (class-of *system*) ',system-class))
            (error "~a executed in the wrong system thread: required ~a, but got ~a"
                   ',name ',system-class (and (class-name (class-of *system*)))))))
       ,@forms)))


(defun register-predefined-callback (event-class-name fn-name)
  (pushnew fn-name (assoc-value *predefined-event-callbacks* event-class-name)))
