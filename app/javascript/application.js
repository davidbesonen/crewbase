// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "bootstrap"

// Custom Turbo Stream actions let us toggle Bootstrap's utility classes in-place.
Turbo.StreamActions.hide = function () {
  this.targetElements.forEach((element) => element.classList.add("d-none"))
}

Turbo.StreamActions.show = function () {
  this.targetElements.forEach((element) => element.classList.remove("d-none"))
}

import "trix"
import "@rails/actiontext"
