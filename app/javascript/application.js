// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
// import "datatables"
// import "datatable_init"

// Disable Turbo globally
Turbo.session.drive = false
