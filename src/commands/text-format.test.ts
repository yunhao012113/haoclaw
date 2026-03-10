import { describe, expect, it } from "vitest";
import { shortenText } from "./text-format.js";

describe("shortenText", () => {
  it("returns original text when it fits", () => {
    expect(shortenText("haoclaw", 16)).toBe("haoclaw");
  });

  it("truncates and appends ellipsis when over limit", () => {
    expect(shortenText("haoclaw-status-output", 10)).toBe("haoclaw-…");
  });

  it("counts multi-byte characters correctly", () => {
    expect(shortenText("hello🙂world", 7)).toBe("hello🙂…");
  });
});
