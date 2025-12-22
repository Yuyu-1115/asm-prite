<template>
  <div class="pixel-editor-container q-pa-md">
    <q-card class="my-card" flat bordered>
      <q-card-section>
        <div class="text-h6">Pixel Art Editor</div>
      </q-card-section>

      <q-card-section class="row q-col-gutter-md">
        <!-- Canvas Area -->
        <div class="col-12 col-md-8 flex flex-center canvas-wrapper">
          <canvas
            ref="canvasRef"
            :width="width"
            :height="height"
            class="pixel-canvas"
            @mousedown="startDrawing"
            @mousemove="draw"
            @mouseup="stopDrawing"
            @mouseleave="stopDrawing"
          ></canvas>
        </div>

        <!-- Controls Area -->
        <div class="col-12 col-md-4">
          <div class="q-gutter-y-md">
            
            <!-- Color Picker -->
            <q-color v-model="currentColor" format-model="hex" no-header no-footer class="my-color-picker" />

            <!-- Tools -->
             <div class="row q-gutter-sm">
                <q-btn icon="brush" :color="currentTool === 'pencil' ? 'primary' : 'grey'" @click="currentTool = 'pencil'" label="Pencil" size="sm" />
                <q-btn icon="format_color_fill" :color="currentTool === 'fill' ? 'primary' : 'grey'" @click="currentTool = 'fill'" label="Fill" size="sm" />
                <q-btn icon="delete" color="negative" @click="clearCanvas" label="Clear" size="sm" />
             </div>

            <q-separator />

            <!-- IO Controls -->
            <div class="q-gutter-y-sm">
              <q-input v-model.number="artId" type="number" label="Art ID" outlined dense />
              
              <div class="row q-gutter-sm">
                 <q-btn color="primary" label="Load" @click="loadArt" :disable="!artId" :loading="loading" />
                 <q-btn color="secondary" label="Download PPM" @click="downloadArt" :disable="!artId" :loading="loading" />
              </div>

               <div class="row q-gutter-sm">
                 <q-btn color="positive" label="Create New" @click="saveArt" :loading="loading" />
                 <q-btn color="warning" label="Update" @click="updateArt" :disable="!artId" :loading="loading" />
              </div>
            </div>

          </div>
        </div>
      </q-card-section>
    </q-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue';
import { parsePPM, toPPM } from '../utils/ppm';
import { useQuasar } from 'quasar';

const $q = useQuasar();

const API_BASE_URL = 'http://localhost:8080';

const width = 64;
const height = 64;
const scale = 8; // Display scale (handled via CSS mostly, but useful for mouse coords)

const canvasRef = ref<HTMLCanvasElement | null>(null);
const ctx = ref<CanvasRenderingContext2D | null>(null);

const currentColor = ref('#000000');
const currentTool = ref<'pencil' | 'fill'>('pencil');
const isDrawing = ref(false);

const artId = ref<number | null>(null);
const loading = ref(false);

onMounted(() => {
  if (canvasRef.value) {
    ctx.value = canvasRef.value.getContext('2d', { willReadFrequently: true });
    clearCanvas();
  }
});

const getMousePos = (e: MouseEvent) => {
  if (!canvasRef.value) return { x: 0, y: 0 };
  const rect = canvasRef.value.getBoundingClientRect();
  const x = Math.floor((e.clientX - rect.left) / (rect.width / width));
  const y = Math.floor((e.clientY - rect.top) / (rect.height / height));
  return { x, y };
};

const startDrawing = (e: MouseEvent) => {
  isDrawing.value = true;
  draw(e);
};

const stopDrawing = () => {
  isDrawing.value = false;
};

const draw = (e: MouseEvent) => {
  if (!isDrawing.value && e.type !== 'click') return;
  if (!ctx.value) return;

  const { x, y } = getMousePos(e);
  
  if (x < 0 || x >= width || y < 0 || y >= height) return;

  if (currentTool.value === 'pencil') {
    ctx.value.fillStyle = currentColor.value;
    ctx.value.fillRect(x, y, 1, 1);
  } else if (currentTool.value === 'fill') {
      // Simple flood fill could be implemented here, but for MVP maybe just fill all?
      // Or implement actual flood fill. Let's do a simple one later if needed. 
      // For now, let's treat fill as fill canvas for MVP simplicity or just omit logic if not critical.
      // Wait, "Fill" usually means flood fill.
      floodFill(x, y, currentColor.value);
      isDrawing.value = false; // Fill is a one-time action per click
  }
};

const hexToRgb = (hex: string) => {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return { r: 0, g: 0, b: 0 };
  return {
    r: parseInt(result[1]!, 16),
    g: parseInt(result[2]!, 16),
    b: parseInt(result[3]!, 16)
  };
};

const getColorAt = (x: number, y: number) => {
    if (!ctx.value) return null;
    const imgData = ctx.value.getImageData(x, y, 1, 1);
    return { 
        r: imgData.data[0] ?? 0, 
        g: imgData.data[1] ?? 0, 
        b: imgData.data[2] ?? 0 
    };
}

const colorsMatch = (c1: {r:number, g:number, b:number}, c2: {r:number, g:number, b:number}) => {
    return c1.r === c2.r && c1.g === c2.g && c1.b === c2.b;
}

const floodFill = (startX: number, startY: number, hexColor: string) => {
    if (!ctx.value) return;
    const targetColor = hexToRgb(hexColor);
    const startColor = getColorAt(startX, startY);
    if (!startColor) return;
    if (colorsMatch(targetColor, startColor)) return;

    const stack = [[startX, startY]];
    const w = width;
    const h = height;

    // We need to work on ImageData for performance
    const imageData = ctx.value.getImageData(0, 0, w, h);
    const data = imageData.data;
    
    // Helper to get index
    const getIdx = (x: number, y: number) => (y * w + x) * 4;
    
    const startR = startColor.r;
    const startG = startColor.g;
    const startB = startColor.b;

    while(stack.length > 0) {
        const pop = stack.pop();
        if(!pop) break;
        const [x, y] = pop;
        
        if (x === undefined || y === undefined) continue;

        const idx = getIdx(x, y);
        
        if (data[idx] === startR && data[idx+1] === startG && data[idx+2] === startB) {
            data[idx] = targetColor.r;
            data[idx+1] = targetColor.g;
            data[idx+2] = targetColor.b;
            data[idx+3] = 255;

            if (x > 0) stack.push([x - 1, y]);
            if (x < w - 1) stack.push([x + 1, y]);
            if (y > 0) stack.push([x, y - 1]);
            if (y < h - 1) stack.push([x, y + 1]);
        }
    }
    
    ctx.value.putImageData(imageData, 0, 0);
}


const clearCanvas = () => {
  if (!ctx.value) return;
  ctx.value.fillStyle = '#FFFFFF';
  ctx.value.fillRect(0, 0, width, height);
};

// API Functions
const loadArt = async () => {
  if (!artId.value) return;
  loading.value = true;
  try {
    const res = await fetch(`${API_BASE_URL}/read?id=${artId.value}`);
    if (!res.ok) throw new Error('Failed to load');
    const text = await res.text();
    const result = parsePPM(text);
    if (result && ctx.value) {
        // Fix for type mismatch: Ensure data is treated correctly as Uint8ClampedArray
        const imgData = new ImageData(new Uint8ClampedArray(result.data), result.width, result.height);
        ctx.value.putImageData(imgData, 0, 0);
        $q.notify({ type: 'positive', message: 'Loaded successfully' });
    }
  } catch (e) {
    console.error(e);
    $q.notify({ type: 'negative', message: 'Failed to load art' });
  } finally {
    loading.value = false;
  }
};

const downloadArt = () => {
    if(!artId.value) return;
    window.open(`${API_BASE_URL}/download?id=${artId.value}`, '_blank');
};

const saveArt = async () => {
    if (!ctx.value) return;
    loading.value = true;
    try {
        const imageData = ctx.value.getImageData(0, 0, width, height);
        const ppm = toPPM(width, height, imageData.data);
        
        const res = await fetch(`${API_BASE_URL}/create`, {
            method: 'POST',
            headers: {
                'Content-Type': 'text/plain'
            },
            body: ppm
        });
        
        if (!res.ok) throw new Error('Failed to create');
        
        let id;
        try {
            const json = await res.json();
            id = json.id || json.art;
        } catch (e) {
            // Fallback: Backend response might be malformed (missing CRLF before body)
            // causing the body to be interpreted as a header.
            // Check headers for the ID.
            const val = res.headers.get('{"id"');
            if (val) {
                id = parseInt(val);
            } else {
                // Try searching all headers
                res.headers.forEach((hVal, hKey) => {
                   if (hKey.includes('"id"')) {
                       const m = hVal.match(/\d+/);
                       if (m) id = parseInt(m[0]);
                   }
                });
            }
            if (!id) throw e;
        }
        
        artId.value = id;
        $q.notify({ type: 'positive', message: `Created art with ID: ${id}` });

    } catch (e) {
        console.error(e);
        $q.notify({ type: 'negative', message: 'Failed to create art' });
    } finally {
        loading.value = false;
    }
};

const updateArt = async () => {
    if (!artId.value || !ctx.value) return;
    loading.value = true;
    try {
        const imageData = ctx.value.getImageData(0, 0, width, height);
        const ppm = toPPM(width, height, imageData.data);
        
        const res = await fetch(`${API_BASE_URL}/update?id=${artId.value}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'text/plain'
            },
            body: ppm
        });
        
        if (!res.ok) throw new Error('Failed to update');
        
        // Response might be empty or json, assume success if ok
        $q.notify({ type: 'positive', message: 'Updated successfully' });

    } catch (e) {
        console.error(e);
        $q.notify({ type: 'negative', message: 'Failed to update art' });
    } finally {
        loading.value = false;
    }
};

</script>

<style scoped>
.pixel-canvas {
  border: 1px solid #ccc;
  image-rendering: pixelated;
  width: 512px; /* 64 * 8 */
  height: 512px;
  cursor: crosshair;
  background-color: white;
  box-shadow: 0 0 10px rgba(0,0,0,0.1);
}

.canvas-wrapper {
    background-color: #f0f0f0;
    padding: 20px;
    border-radius: 8px;
}

.my-color-picker {
    width: 100%;
    max-width: 250px;
}
</style>
