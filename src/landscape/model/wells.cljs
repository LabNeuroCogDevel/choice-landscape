(ns landscape.model.wells
(:require [landscape.settings :refer [BOARD]]
          [debux.cs.core :as d :refer-macros [clog clogn dbg dbgn dbg-last break]]
          [landscape.utils :as utils]
          [landscape.sound :as snd]))

(defn well-pos
  "{:x # :y #} for a number of steps/count to a well"
  [side step]
  (let [center-x (:center-x BOARD)
        bottom-y (- (:bottom-y BOARD) 5)
        move-by (reduce + (take step (:step-sizes BOARD)))]
    (case side
      :left  {:x (- center-x move-by) :y bottom-y}
      :up    {:x center-x             :y (- bottom-y move-by)}
      :right {:x (+ center-x move-by) :y bottom-y}
      {:x 0 :y 0})))

(defn well-add-pos
  "uses :step to calc :pos on well info (e.g. map within [:wells :left]) "
  [side {:keys [step] :as well}]
  (assoc well :pos (well-pos side step)))

(defn wells-state-fresh
  ;; include default settings
  [wells]
  (let [wells (if wells
                 wells
                 {:left  {:step 2 :open true :active-at 0 :prob 100 :color :red}
                  :up    {:step 1 :open true :active-at 0 :prob 20  :color :green}
                  :right {:step 1 :open true :active-at 0 :prob 80  :color :blue}})]
    (reduce #(update %1 %2 (partial well-add-pos %2)) wells (keys wells))))

(defn wells-set-open-or-close
  ^{:doc "set if we can go to a well (and if we show a bucket)"
    :test (fn[] (assert (=
                {:wells {:left {:open false}}}
                (wells-set-open-or-close {:wells {:left {:open true}}} [:left] false)
                )))}
 [{:keys [wells] :as state} sides open?]
 (reduce #(assoc-in %1 [:wells %2 :open] open?) state sides))

(defn wells-close [{:keys [wells] :as state}]
  (wells-set-open-or-close state [:left :up :right] false))

(defn wells-open-rand [{:keys [wells] :as state}]
  (wells-set-open-or-close state (take 2 (shuffle [:left :up :right])) true))

(defn wells-update-which-open
        "when just came into chose state, set wells
  TODO: maybe not random but set before"
        [{:keys [time-cur phase] :as state}]
        (let [phasechange? (= (:start-at phase) time-cur)
              phasename (:name phase)]
          (if (not phasechange?)
            state
            (case phasename
              :chose (wells-open-rand state)
              :waiting (wells-close state)
              ;; :feedback state
              state))))

(defn hit-now
  [wells time-cur]
  (filter some? (map  #(if (= time-cur (-> wells % :active-at)) % nil) (keys wells))))

(defn activate-well
  "when collision with 'apos' check prob and set score.
  NB. see any :active-at == :time-cur to trigger other things"
  [apos now well]
  (if (and (= 0 (:active-at well))
           (utils/collide? (:pos well) apos))
    (assoc well :active-at now :score (utils/prob-gets-points? (:prob well)))
    well))

(defn wells-check-collide
        "use active-well to set active-at (start animation) if avatar is over well"
        [{:keys  [wells avatar time-cur] :as state}]
        (let [apos (:pos avatar)]
          (assoc state :wells
                 (reduce #(update %1 %2 (partial activate-well apos time-cur))
                         wells
                         (keys wells)))))


(defn well-off [time well]
  ;; TODO: 1000 should come from sprite total-size?
  (update-in well [:active-at] #(if (> (- time %) (:wait-time BOARD)) 0 %)))

(defn wells-turn-off [{:keys [wells time-cur] :as state}]
  (assoc state :wells
    (reduce #(update %1 %2 (partial well-off time-cur)) wells (keys wells))))


;; but we probably want to express wells as wide instead of nested
;; and want to be able to easily get at picked and avoided
;; like
;;   :pick-prob # :picked-far? ?
;;   :avoid-prob # :avoid-far? ?
;;   :left-prob # :up-prob # :right-prob #
;;   :left-on ? :up-on ? :right-on ?
;;   :left-far ? :up-far ? :right-far ?
;; this could be fn as wells/wide-info
(defn zipmap-fn [keys fnx] (zipmap keys (mapv fnx keys)))
(defn side-wide [wells side]
  (let [items [:prob :step :open]
        keys  (mapv #(keyword (str (name side) "-" (name %))) items)
        info  (mapv #(get-in wells [side %]) items)]
    (zipmap keys info)))
(defn wide-info
  "'wide' format info for well side x well info. for http post"
  [wells]
  (reduce #'merge (mapv #(side-wide wells %) [:left :up :right])))

(defn avoided
  "find the well we didn't pick that was open.
  returns list but should only have one output"
  [wells picked]
  (filter #(and (not= picked %) (get-in wells [% :open])) (keys wells)))
(defn wide-info-picked
  "after picking wide info (avoided and picked). useful for http post"
  [wells picked]
  (let [avoided (first (avoided wells picked))]
    {:avoided avoided
     :picked-prob (get-in wells [picked :prob])
     :picked-step (get-in wells [avoided :step])
     :avoided-prob (get-in wells [avoided :prob])
     :avoided-step (get-in wells [avoided :step])}))
