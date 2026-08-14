import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "billingBypass" ]

  fill() {
    const suffix = Math.floor(Math.random() * 9000) + 1000

    this.set("company_name", `Northstar Production Co. ${suffix}`)
    this.set("company_description", "Full-service live production company supporting concerts, corporate events, and touring crews.")
    this.set("company_contact_email", `hello+${suffix}@northstarproduction.test`)
    this.set("company_contact_phone", "402-555-0147")
    this.set("company_locations_attributes_0_city", "Lincoln")
    this.set("company_locations_attributes_0_country", "United States")
    this.set("company_locations_attributes_0_state", "NE")
    this.set("company_founded_at", "2018-05-15")
    this.set("company_website_url", "https://northstarproduction.test")
    this.set("company_twitter_handle", "@northstarproduction")
    this.set("company_instagram_handle", "@northstarproduction")
    this.set("company_tiktok_handle", "@northstarproduction")
    this.set("company_linkedin_url", "https://www.linkedin.com/company/northstar-production")
    this.set("company_facebook_url", "https://www.facebook.com/northstarproduction")
    this.set("company_youtube_url", "https://www.youtube.com/@northstarproduction")

    const visibility = this.element.querySelector("#company_is_public")
    if (visibility) visibility.checked = true
    if (this.hasBillingBypassTarget) this.billingBypassTarget.value = "1"

    this.element.querySelector("#company_name")?.focus()
  }

  set(id, value) {
    const field = this.element.querySelector(`#${id}`)
    if (!field) return

    field.value = value
    field.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
