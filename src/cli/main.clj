(ns cli.main
  (:gen-class)
  (:require [next.jdbc :as jdbc])
  #_(:import (org.sqlite JDBC)))

(def ds "jdbc:sqlite::memory:")

(defn test-connection! []
  (jdbc/execute! ds ["select datetime('now') as now"]))

(defn -main [& args]
  (prn (test-connection!)))

(comment


  (prn :foo)

  #_:end)
