declare module 'html-to-image' {
  export interface Options {
    cacheBust?: boolean;
    pixelRatio?: number;
    backgroundColor?: string | null;
    width?: number;
    height?: number;
    style?: Record<string, string>;
    filter?: (node: Node) => boolean;
    imagePlaceholder?: string;
    fontEmbedCSS?: string;
    skipAutoScale?: boolean;
    preferredFontFormat?: 'woff' | 'woff2' | 'truetype' | 'opentype';
  }

  export function toPng(node: HTMLElement, options?: Options): Promise<string>;
  export function toJpeg(node: HTMLElement, options?: Options): Promise<string>;
  export function toBlob(node: HTMLElement, options?: Options): Promise<Blob | null>;
  export function toPixelData(node: HTMLElement, options?: Options): Promise<Uint8ClampedArray>;
  export function toSvg(node: HTMLElement, options?: Options): Promise<string>;
}

