// opencode: sincroniza la boveda de Obsidian (memoria compartida de los agentes).
// session.created -> vault-sync.sh start (sube lo pendiente + pull)   session.idle (termino de responder) -> vault-sync.sh push
// El script nunca falla hacia afuera y usa un lock, asi que llamarlo seguido es seguro.
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const SCRIPT = join(homedir(), "Salchipapa.Dots", "SalchipapaObsidian", "vault-sync.sh");
const childSessions = new Set();

function sync(mode) {
  const child = spawn("bash", [SCRIPT, mode, "opencode"], { detached: true, stdio: "ignore" });
  child.on("error", () => {});
  child.unref();
}

export const VaultSyncPlugin = async () => ({
  event: async ({ event }) => {
    const info = event?.properties?.info;
    // Las subsesiones (subagentes) no sincronizan: solo la sesion principal
    if (info?.id && info.parentID) {
      childSessions.add(info.id);
      return;
    }
    const sessionID = event?.properties?.sessionID ?? info?.id;
    if (sessionID && childSessions.has(sessionID)) return;

    if (event?.type === "session.created") sync("start");
    else if (event?.type === "session.idle") sync("push");
  },
});

export default {
  id: "salchipapa.vault-sync",
  server: VaultSyncPlugin,
  setup() {},
};
