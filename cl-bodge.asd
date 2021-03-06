(asdf:defsystem cl-bodge/utils
  :description "Various utilities for cl-bodge"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (bodge-utilities)
  :pathname "utils/"
  :serial t
  :components ((:file "utils")))


(asdf:defsystem cl-bodge/engine
  :description "Bodacious Game Engine foundation library"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (:cl-bodge/utils :bodge-memory :bodge-math :bodge-concurrency
               :bodge-blobs-support :claw :claw-utils :log4cl
               :local-time :cffi :cl-flow :uiop :simple-flow-dispatcher
               :cl-muth :float-features :bodge-libc-essentials)
  :pathname "engine/"
  :serial t
  :components ((:file "packages")
               (:module events
                :components ((:file "event")
                             (:file "emitter")
                             (:file "listener")
                             (:file "hub")))
               (:file "properties")
               (:file "engine")
               (:file "handle")
               (:file "event")
               (:file "generic-system")
               (:file "thread-bound-system")))


(asdf:defsystem cl-bodge/resources
  :description "Bodacious Game Engine resource management"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/utils cl-bodge/engine flexi-streams
               opticl cl-fad chipz log4cl static-vectors
               sndfile-blob bodge-sndfile cl-conspack)
  :pathname "resources/"
  :serial t
  :components ((:file "packages")
               (:file "storage")
               (:file "handler")
               (:file "registry")
               (:module chunked :serial t
                :components ((:file "resource")
                             (:file "container")
                             (:file "chunk-structure")))
               (:file "audio")
               (:file "image")
               (:file "font")
               (:file "font-atlas")
               (:module scene :serial t
                :components ((:file "scene")
                             (:file "read")
                             (:file "write")
                             (:file "handler")))))


(asdf:defsystem cl-bodge/host
  :description "Bodacious Game Engine host system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine bodge-host cl-bodge/utils log4cl cl-muth)
  :pathname "host/"
  :serial t
  :components ((:file "packages")
               (:file "events")
               (:file "system")
               (:file "hotkey")
               (:file "input-map")))


(asdf:defsystem cl-bodge/graphics
  :description "Bodacious Game Engine graphics system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils cl-bodge/host cl-bodge/resources
                               cl-opengl log4cl local-time cffi cl-ppcre
                               glad-blob bodge-glad static-vectors)
  :pathname "graphics/"
  :serial t
  :components ((:file "packages")
               (:file "utils")
               (:file "state")
               (:file "sync")
               (:module "input" :components ((:file "common")
                                             (:file "types")
                                             (:file "buffers")
                                             (:file "array-buffer")
                                             (:file "index-buffer")
                                             (:file "uniforms")
                                             (:file "amalgams")
                                             (:file "structs")
                                             (:file "textures")))
               (:module "output" :components ((:file "output")
                                              (:file "default")
                                              (:file "textures")
                                              (:file "renderbuffer")
                                              (:file "attachments")
                                              (:file "framebuffer")))
               (:file "shader-registry")
               (:file "shader")
               (:file "pipeline")
               (:file "rendering")
               (:file "context")
               (:file "system")))


(asdf:defsystem cl-bodge/canvas
  :description "Bodacious Game Engine vector graphics system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils cl-bodge/graphics
                               bodge-canvas cl-bodge/resources
                               trivial-garbage)
  :pathname "canvas/"
  :serial t
  :components ((:file "packages")
               (:file "canvas")
               (:file "paint")
               (:file "drawing")))


(asdf:defsystem cl-bodge/animation
  :description "Bodacious Game Engine animation library"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils cl-bodge/resources cl-bodge/graphics)
  :pathname "animation/"
  :serial t
  :components ((:file "packages")
               (:file "keyframed")
               (:file "stream")
               (:file "resources")))


(asdf:defsystem cl-bodge/audio
  :description "Bodacious Game Engine audio system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils cl-bodge/host log4cl
                               cl-bodge/resources
                               openal-blob bodge-openal)
  :pathname "audio/"
  :serial t
  :components ((:file "packages")
               (:file "al")
               (:file "buffer")
               (:file "source")
               (:file "system")))


(asdf:defsystem cl-bodge/physics/backend
  :description "Bodacious Game Engine physics system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :pathname "physics/backend"
  :serial t
  :components ((:file "packages")
               (:file "backend")))


(asdf:defsystem cl-bodge/physics
  :description "Bodacious Game Engine physics system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/utils cl-bodge/engine cl-bodge/physics/backend)
  :pathname "physics/"
  :serial t
  :components ((:file "packages")
               (:file "api")
               (:file "system")))


(asdf:defsystem cl-bodge/physics/3d
  :description "Bodacious Game Engine physics system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/utils cl-bodge/engine cl-bodge/physics/backend
                              ode-blob bodge-ode log4cl claw local-time)
  :pathname "physics/3d/"
  :serial t
  :components ((:file "packages")
               (:file "common")
               (:module ode :components ((:file "ode")
                                         (:file "contacts")
                                         (:file "universe")
                                         (:file "mass")
                                         (:file "rigid-body")
                                         (:file "joints")
                                         (:file "geometry")))
               (:file "engine")
               (:file "universe")
               (:file "mass")
               (:file "contact")
               (:file "rigid-body")
               (:file "shape")))


(asdf:defsystem cl-bodge/physics/2d
  :description "Bodacious Game Engine physics system"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/utils cl-bodge/engine cl-bodge/physics/backend
                              chipmunk-blob bodge-chipmunk log4cl claw
                              trivial-garbage cffi)
  :pathname "physics/2d/"
  :serial t
  :components ((:file "packages")
               (:file "utils")
               (:file "chipmunk")
               (:file "contact")
               (:file "universe")
               (:file "body")
               (:file "shape")
               (:file "joint")))


(asdf:defsystem cl-bodge/shading
  :description "Bodacious Game Engine shading library"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils cl-bodge/graphics)
  :pathname "shading/"
  :serial t
  :components ((:file "packages")
               (:file "math/math")
               (:file "shadow/shadow")
               (:file "phong/phong")
               (:file "banner/banner")
               (:file "skinning/skinning")
               (:file "filament/filament")))


(asdf:defsystem cl-bodge/text
  :description "Bodacious Game Engine text rendering"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils cl-bodge/resources
                               cl-bodge/graphics log4cl)
  :pathname "text/"
  :serial t
  :components ((:file "packages")
               (:file "font")
               (:file "text")
               (:file "rated-queue")
               (:file "text-cache")
               (:module shaders :components ((:file "text")))
               (:file "text-renderer")
               (:file "resources")))


(asdf:defsystem cl-bodge/ui
  :description "Bodacious Game Engine Plain Old Interface for Users"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils bodge-ui cl-bodge/graphics cl-bodge/canvas
                               cl-bodge/host claw)
  :pathname "ui/"
  :serial t
  :components ((:file "packages")
               (:file "input-source")
               (:file "rendering")
               (:file "ui")))


(asdf:defsystem cl-bodge/scene
  :description "Bodacious Game Engine scene handling"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/utils cl-bodge/engine)
  :pathname "scene/"
  :serial t
  :components ((:file "packages")
               (:file "scene")))


(asdf:defsystem cl-bodge/appkit
  :description "Simple facade for cl-bodge facilities"
  :version "1.0.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (log4cl cl-bodge/graphics cl-bodge/audio cl-bodge/host
                      cl-bodge/resources cl-bodge/canvas cl-bodge/ui
                      uiop cl-muth cl-fad cl-muth)
  :pathname "appkit/"
  :serial t
  :components ((:file "packages")
               (:file "appkit")))


(asdf:defsystem cl-bodge/distribution
  :description "Bodacious Game Engine distribution helpers"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/utils cl-bodge/resources asdf uiop cl-fad cffi cl-ppcre
                               bodge-blobs-support inferior-shell split-sequence flexi-streams
                               trivial-features)
  :pathname "distribution/"
  :serial t
  :components ((:file "packages")
               (:file "utils")
               (:file "distribution")
               (:file "registry")
               (:module darwin
                :if-feature :darwin
                :components ((:file "build")))
               (:module unix
                :if-feature (:and :unix (:not :darwin))
                :components ((:file "build")))
               (:module windows
                :if-feature (:or :windows :win32)
                :components ((:file "build")))
               (:file "build-unknown" :if-feature (:not (:or :darwin :unix :win32 :windows)))
               (:file "build")))


(asdf:defsystem cl-bodge/tests
  :description "Test suite for cl-bodge engine"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/utils cl-bodge/text flexi-streams fiveam)
  :pathname "t/"
  :serial t
  :components ((:file "packages")
               (:file "suites")
               (:file "rated-queue")
               (:file "circular-buffer")
               (:file "buffered-output-stream")))


(asdf:defsystem cl-bodge
  :description "Bodacious Game Engine framework"
  :version "0.4.0"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (cl-bodge/engine cl-bodge/utils
                               cl-bodge/host cl-bodge/graphics cl-bodge/audio
                               cl-bodge/physics
                               cl-bodge/physics/2d cl-bodge/physics/3d
                               cl-bodge/resources cl-bodge/ui cl-bodge/text
                               cl-bodge/canvas cl-bodge/animation
                               cl-bodge/shading cl-bodge/scene cl-bodge/appkit)
  :components ((:file "packages")))
