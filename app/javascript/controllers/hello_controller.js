import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output"];

  connect() {
    this.outputTarget.textContent = "Hello World!";
  }

  greet() {
    const name = this.outputTarget.dataset.name || "World";
    this.outputTarget.textContent = `Hello, ${name}!`;
  }
}
