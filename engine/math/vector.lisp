(in-package :cl-bodge.math)


(defmacro %raw-> (type val)
  `(make-instance ',type :value ,val))


(definline vec->array (vec)
  (value-of vec))


(definline vec3 (&optional (x #f0) (y #f0) (z #f0))
  (%raw-> vec3 (v3:make x y z)))


(definline vec4 (&optional (x #f0) (y #f0) (z #f0) (w #f0))
  (%raw-> vec4 (v4:make x y z w)))


(definline vec2 (&optional (x #f0) (y #f0))
  (%raw-> vec2 (v2:make x y)))


(definline copy-vec3 (vec)
  (%raw-> vec3 (v3:make (vref vec 0) (vref vec 1) (vref vec 2))))


(defgeneric make-vec3 (val &key))


(defmethod make-vec3 ((vec vec4) &key)
  (%raw-> vec3 (v3:make (vref vec 0) (vref vec 1) (vref vec 2))))


(definline sequence->vec3 (seq)
  (vec3 (elt seq 0)
        (elt seq 1)
        (elt seq 2)))


(defun vref (vec idx)
  (let ((vec (value-of vec)))
    (ecase idx
      (0 (v:x vec))
      (1 (v:y vec))
      (2 (v:z vec))
      (3 (v:w vec)))))


(defun (setf vref) (value vec idx)
  (let ((vec (value-of vec)))
    (ecase idx
      (0 (setf (v:x vec) value))
      (1 (setf (v:y vec) value))
      (2 (setf (v:z vec) value))
      (3 (setf (v:w vec) value)))))


(defmethod summarize ((this vec3) (that vec3))
  (%raw-> vec3 (v3:+ (value-of this) (value-of that))))


(defmethod lerp ((this vec3) (that vec3) f)
  (%raw-> vec3 (v3:lerp (value-of this) (value-of that) f)))


(defmethod normalize ((this vec3))
  (%raw-> vec3 (v3:normalize (value-of this))))


(defmethod multiply ((this vec3) (scalar single-float))
  (%raw-> vec3 (v3:*s (value-of this) scalar)))