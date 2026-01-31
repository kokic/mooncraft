async function loadImage(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`failed to load image: ${url}`);
  }
  const blob = await response.blob();
  const img = new Image();
  await new Promise((resolve, reject) => {
    img.onload = resolve;
    img.onerror = reject;
    img.src = URL.createObjectURL(blob);
  });
  return img;
}

export {
  loadImage,
};
