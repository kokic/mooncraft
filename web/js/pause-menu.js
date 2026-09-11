function ensurePauseMenuStyles() {
  if (document.getElementById("mc-pause-menu-style")) return;
  const style = document.createElement("style");
  style.id = "mc-pause-menu-style";
  style.textContent = `
    .mc-pause-menu {
      position: fixed;
      inset: 0;
      z-index: 50;
      display: grid;
      place-items: center;
      padding: 20px;
      background: rgba(8, 12, 16, 0.55);
      font-family: system-ui, sans-serif;
    }
    .mc-pause-menu[hidden] { display: none; }
    .mc-pause-panel {
      width: min(360px, 100%);
      box-sizing: border-box;
      padding: 24px;
      border: 1px solid rgba(213, 224, 231, 0.22);
      border-radius: 6px;
      background: #20262a;
      box-shadow: 0 18px 42px rgba(0, 0, 0, 0.42);
      color: #f4f7f8;
      text-align: center;
    }
    .mc-pause-title {
      margin: 0 0 20px;
      font-size: 24px;
      font-weight: 650;
      letter-spacing: 0;
    }
    .mc-pause-actions {
      display: grid;
      gap: 10px;
    }
    .mc-pause-action {
      min-height: 42px;
      border: 1px solid transparent;
      border-radius: 4px;
      color: #ffffff;
      font: inherit;
      font-weight: 650;
      cursor: pointer;
    }
    .mc-pause-action:focus-visible {
      outline: 2px solid #d7ecff;
      outline-offset: 2px;
    }
    .mc-pause-resume {
      border-color: #3d91c9;
      background: #1976a8;
    }
    .mc-pause-resume:hover { background: #2387bb; }
    .mc-pause-save-quit {
      border-color: #975f56;
      background: #7f3f37;
    }
    .mc-pause-save-quit:hover { background: #975047; }
    .mc-pause-action:disabled {
      cursor: wait;
      opacity: 0.65;
    }
    .mc-pause-status {
      min-height: 18px;
      margin: 14px 0 0;
      color: #ffc1b8;
      font-size: 13px;
      line-height: 18px;
    }
  `;
  document.head.appendChild(style);
}

function createPauseMenu({
  parent = document.body,
  onOpen,
  onResume,
  onSaveAndQuit,
  designer = false,
} = {}) {
  ensurePauseMenuStyles();

  const host = document.createElement("div");
  host.className = "mc-pause-menu";
  host.hidden = true;
  host.setAttribute("role", "dialog");
  host.setAttribute("aria-modal", "true");
  host.setAttribute("aria-label", "Game menu");

  const panel = document.createElement("section");
  panel.className = "mc-pause-panel";
  const title = document.createElement("h1");
  title.className = "mc-pause-title";
  title.textContent = "Game Menu";
  panel.appendChild(title);

  const actions = document.createElement("div");
  actions.className = "mc-pause-actions";
  const resumeButton = document.createElement("button");
  resumeButton.className = "mc-pause-action mc-pause-resume";
  resumeButton.type = "button";
  resumeButton.textContent = "Resume Game";
  const saveQuitButton = document.createElement("button");
  saveQuitButton.className = "mc-pause-action mc-pause-save-quit";
  saveQuitButton.type = "button";
  saveQuitButton.textContent = designer ? "Exit Designer" : "Save and Quit";
  actions.append(resumeButton, saveQuitButton);
  panel.appendChild(actions);

  const status = document.createElement("p");
  status.className = "mc-pause-status";
  status.setAttribute("aria-live", "polite");
  panel.appendChild(status);
  host.appendChild(panel);
  parent.appendChild(host);

  let open = false;
  let saving = false;

  const render = () => {
    host.hidden = !open;
    resumeButton.disabled = saving;
    saveQuitButton.disabled = saving;
    saveQuitButton.textContent = saving
      ? "Saving..."
      : designer
        ? "Exit Designer"
        : "Save and Quit";
  };

  const setOpen = (next) => {
    if (saving || open === next) return;
    open = next;
    render();
    if (open) {
      if (typeof onOpen === "function") onOpen();
      resumeButton.focus();
    } else if (typeof onResume === "function") {
      onResume();
    }
  };

  const saveAndQuit = async () => {
    if (saving || typeof onSaveAndQuit !== "function") return;
    saving = true;
    status.textContent = "";
    render();
    try {
      await onSaveAndQuit();
    } catch (error) {
      console.error("[save] failed to save and quit", error);
      status.textContent = "Unable to save the world.";
      saving = false;
      render();
    }
  };

  const onKeyDown = (event) => {
    if (event.code !== "Escape" || event.repeat) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    setOpen(!open);
  };

  resumeButton.addEventListener("click", () => setOpen(false));
  saveQuitButton.addEventListener("click", () => { void saveAndQuit(); });
  window.addEventListener("keydown", onKeyDown, { capture: true });

  return {
    isOpen: () => open,
    dispose: () => {
      window.removeEventListener("keydown", onKeyDown, { capture: true });
      host.remove();
    },
  };
}

export {
  createPauseMenu,
};
