import { Application } from "@hotwired/stimulus";
import { getByText } from "@testing-library/dom";
import HelloController from "../hello_controller";

describe("HelloController", () => {
  let application;
  let container;

  beforeEach(() => {
    container = document.createElement("div");
    container.innerHTML = `
      <div data-controller="hello">
        <span data-hello-target="output" data-name="Test User"></span>
      </div>
    `;
    document.body.appendChild(container);

    application = Application.start();
    application.register("hello", HelloController);
  });

  afterEach(() => {
    document.body.removeChild(container);
  });

  it("sets initial text on connect", () => {
    expect(getByText(container, "Hello World!")).toBeInTheDocument();
  });

  it("updates text when greet is called", () => {
    const controller = application.getControllerForElementAndIdentifier(
      container.querySelector("[data-controller=hello]"),
      "hello"
    );
    controller.greet();
    expect(getByText(container, "Hello, Test User!")).toBeInTheDocument();
  });
});
