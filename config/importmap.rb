# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# pin "bootstrap" # @5.3.7
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"
pin "flatpickr", to: "https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.js"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "chart.js/auto", to: "https://cdn.jsdelivr.net/npm/chart.js@4.5.0/auto/+esm"
