function createChatUI({
  parent = document.body,
  canOpen = () => true,
  onSubmit = null,
  onOpen = null,
  onClose = null,
} = {}) {
  const host = document.createElement("div");
  host.className = "mc-chat";
  host.style.position = "fixed";
  host.style.inset = "0";
  host.style.display = "none";
  host.style.zIndex = "10";
  host.style.pointerEvents = "auto";
  host.style.background = "rgba(0, 0, 0, 0.46)";

  const panel = document.createElement("div");
  panel.className = "mc-chat-panel";
  panel.style.position = "absolute";
  panel.style.left = "12px";
  panel.style.bottom = "68px";
  panel.style.width = "min(620px, calc(100vw - 24px))";
  panel.style.maxHeight = "min(34vh, 320px)";
  panel.style.display = "flex";
  panel.style.flexDirection = "column";
  panel.style.gap = "8px";
  panel.style.padding = "10px";
  panel.style.boxSizing = "border-box";
  panel.style.background = "rgba(0, 0, 0, 0.62)";
  panel.style.border = "1px solid rgba(255, 255, 255, 0.16)";
  panel.style.borderRadius = "3px";
  panel.style.boxShadow = "0 8px 24px rgba(0, 0, 0, 0.35)";
  panel.style.color = "#ffffff";
  panel.style.font = "14px/1.35 monospace";

  const messages = document.createElement("div");
  messages.style.minHeight = "32px";
  messages.style.maxHeight = "230px";
  messages.style.overflowY = "auto";
  messages.style.overflowX = "hidden";
  messages.style.whiteSpace = "pre-wrap";
  messages.style.overflowWrap = "anywhere";
  messages.style.scrollbarWidth = "thin";
  panel.appendChild(messages);

  const input = document.createElement("input");
  input.className = "mc-chat-input";
  input.type = "text";
  input.autocomplete = "off";
  input.spellcheck = false;
  input.setAttribute("aria-label", "Chat input");
  input.placeholder = "Chat";
  input.style.width = "100%";
  input.style.boxSizing = "border-box";
  input.style.padding = "7px 8px";
  input.style.border = "1px solid rgba(255, 255, 255, 0.28)";
  input.style.borderRadius = "2px";
  input.style.outline = "none";
  input.style.background = "rgba(0, 0, 0, 0.7)";
  input.style.color = "#ffffff";
  input.style.font = "inherit";
  input.style.caretColor = "#ffffff";
  panel.appendChild(input);
  host.appendChild(panel);
  parent.appendChild(host);

  const state = { open: false };
  const maxMessages = 100;
  let hideTimer = null;
  const stopInputPropagation = (event) => {
    if (state.open) event.stopPropagation();
  };
  input.addEventListener("keydown", stopInputPropagation);

  const addMessage = (text, tone = "chat") => {
    const line = document.createElement("div");
    line.textContent = String(text ?? "");
    line.style.color = tone === "error"
      ? "#ff9d9d"
      : tone === "success"
        ? "#b7f7b7"
        : "#ffffff";
    messages.appendChild(line);
    while (messages.childElementCount > maxMessages) {
      messages.firstElementChild?.remove();
    }
    messages.scrollTop = messages.scrollHeight;
  };

  const setOpen = (open, initialText = "", lingerMessages = false) => {
    const next = open === true;
    if (next && !state.open && typeof canOpen === "function" && !canOpen()) {
      return false;
    }
    if (state.open === next) {
      if (next) {
        input.focus();
        input.setSelectionRange(input.value.length, input.value.length);
      } else if (!lingerMessages) {
        if (hideTimer) clearTimeout(hideTimer);
        host.style.display = "none";
      }
      return true;
    }
    if (hideTimer) clearTimeout(hideTimer);
    hideTimer = null;
    state.open = next;
    if (next) {
      host.style.display = "block";
      host.style.pointerEvents = "auto";
      host.style.background = "rgba(0, 0, 0, 0.46)";
      panel.style.background = "rgba(0, 0, 0, 0.62)";
      input.style.display = "block";
      input.value = initialText;
      input.focus();
      input.setSelectionRange(input.value.length, input.value.length);
      if (typeof onOpen === "function") onOpen();
    } else {
      input.value = "";
      input.style.display = "none";
      host.style.pointerEvents = "none";
      host.style.background = "transparent";
      panel.style.background = "rgba(0, 0, 0, 0.44)";
      if (lingerMessages && messages.childElementCount > 0) {
        host.style.display = "block";
        hideTimer = setTimeout(() => {
          if (!state.open) host.style.display = "none";
          hideTimer = null;
        }, 5000);
      } else {
        host.style.display = "none";
      }
      if (typeof onClose === "function") onClose();
    }
    return true;
  };

  const submit = () => {
    const text = input.value;
    if (text.length === 0) {
      setOpen(false);
      return;
    }
    addMessage(text);
    let result = null;
    try {
      result = typeof onSubmit === "function" ? onSubmit(text) : null;
    } catch (error) {
      console.error("[chat] submit failed", error);
      result = { success: false, message: "Unable to submit chat message" };
    }
    if (result && typeof result.message === "string" && result.message.length > 0) {
      addMessage(result.message, result.success === false ? "error" : "success");
    }
    setOpen(false, "", true);
  };

  host.addEventListener("mousedown", (event) => {
    if (!state.open || event.target === input) return;
    event.preventDefault();
    input.focus();
  });

  const isEditableTarget = (target) => {
    if (!(target instanceof HTMLElement)) return false;
    return target === input || target.isContentEditable ||
      target.tagName === "TEXTAREA" || target.tagName === "SELECT";
  };

  const onKeyDown = (event) => {
    if (state.open) {
      if (event.code === "Escape") {
        event.preventDefault();
        event.stopImmediatePropagation();
        setOpen(false);
        return;
      }
      if (event.code === "Enter" && !event.isComposing) {
        event.preventDefault();
        event.stopImmediatePropagation();
        submit();
        return;
      }
      if (event.target !== input) {
        event.preventDefault();
        event.stopImmediatePropagation();
        input.focus();
      }
      return;
    }
    if (event.repeat || !canOpen() || isEditableTarget(event.target)) return;
    const slash = event.key === "/" ||
      (event.code === "Slash" && !event.shiftKey);
    const chatKey = event.code === "KeyC" &&
      !event.ctrlKey && !event.altKey && !event.metaKey;
    if (!slash && !chatKey) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    setOpen(true, slash ? "/" : "");
  };

  window.addEventListener("keydown", onKeyDown, { capture: true });

  return {
    host,
    input,
    addMessage,
    setOpen,
    isOpen: () => state.open,
    dispose: () => {
      if (hideTimer) clearTimeout(hideTimer);
      window.removeEventListener("keydown", onKeyDown, { capture: true });
      input.removeEventListener("keydown", stopInputPropagation);
      host.remove();
    },
  };
}

export { createChatUI };
