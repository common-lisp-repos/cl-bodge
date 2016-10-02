(in-package :cl-user)

(defpackage :cl-bodge.definition
  (:use :cl :asdf))

(in-package :cl-bodge.definition)

(defsystem cl-bodge
  :description "Bodacious Game Engine"
  :version "0.0.1"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (alexandria cl-opengl cl-glfw3 cl-muth split-sequence sb-cga
                          log4cl bordeaux-threads trivial-main-thread)
  :serial t
  :components ((:file "packages")
               (:module utils
                        :serial t
                        :components ((:file "utils")))
               (:module math
                        :serial t
                        :components ((:file "types")
                                     (:file "vector")
                                     (:file "matrix")))
               (:module engine
                        :serial t
                        :components ((:file "engine")))
               (:module concurrency
                        :serial t
                        :components ((:file "job-queue")))
               (:module application
                        :serial t
                        :components ((:file "application")))
               (:module graphics
                        :serial t
                        :components ((:file "gl")
                                     (:file "renderable")
                                     (:file "vertex-array")
                                     (:file "buffers")
                                     (:file "shading")
                                     (:file "graphics")))))
