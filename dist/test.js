
class HotbarBackground extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this.shadowRoot.innerHTML = `  
                    <style>  
                        :host {  
                            display: block;  
                            width: 182px;  
                            height: 22px;  
                            background-image: var(--hotbar-bg-image);  
                            background-size: cover;  
                            background-repeat: no-repeat;  
                        }  
                    </style>  
                `;
  }

  async connectedCallback() {
    await this.loadHotbarBackground();
  }

  async loadHotbarBackground() {
    try {
      const response = await fetch('assets/images/gui/widgets.png');
      const blob = await response.blob();
      const img = new Image();

      await new Promise((resolve, reject) => {
        img.onload = resolve;
        img.onerror = reject;
        img.src = URL.createObjectURL(blob);
      });

      // 使用 Canvas 裁剪 hotbar-background 区域 (0, 0, 182, 22)  
      const canvas = document.createElement('canvas');
      canvas.width = 182;
      canvas.height = 22;
      const ctx = canvas.getContext('2d');

      const coordZoomFactor = img.width / 256;
      ctx.drawImage(
        img,
        0, 0, 182 * coordZoomFactor, 22 * coordZoomFactor,
        0, 0, 182, 22
      );

      const croppedUrl = canvas.toDataURL();
      this.shadowRoot.host.style.setProperty('--hotbar-bg-image', `url(${croppedUrl})`);

    } catch (error) {
      console.error('Failed to load hotbar background:', error);
    }
  }
}

customElements.define('hotbar-background', HotbarBackground);