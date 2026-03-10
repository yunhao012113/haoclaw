import type {
  AnyAgentTool,
  HaoclawPluginApi,
  HaoclawPluginToolFactory,
} from "haoclaw/plugin-sdk/lobster";
import { createLobsterTool } from "./src/lobster-tool.js";

export default function register(api: HaoclawPluginApi) {
  api.registerTool(
    ((ctx) => {
      if (ctx.sandboxed) {
        return null;
      }
      return createLobsterTool(api) as AnyAgentTool;
    }) as HaoclawPluginToolFactory,
    { optional: true },
  );
}
