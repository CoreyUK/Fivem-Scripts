// NUI Script: Manages tire wear UI for FiveM

const app = document.getElementById('tyre-wear-app');
const container = document.getElementById('tyre-container');
const wheelNames = ['FL', 'FR', 'RL', 'RR', 'M1L', 'M1R', 'M2L', 'M2R'];

// Debounce settings
let debounceTimer;
const DEBOUNCE_TIME = 100; // Milliseconds

// Style constants
const pureBlack = '#000000';
const transparent = 'transparent';

// Process tire durability updates
const processUpdate = (data) => {
    if (data.action !== 'updateTyres' || !data.data) return;

    const durability = data.data.durability || [];
    const wheelCount = Math.min(parseInt(data.data.wheelCount) || 0, wheelNames.length);
    const vehicleType = data.data.vehicleType || 'car';

    // Set container class for vehicle type (car/bike)
    container.className = 'tyre-container';
    container.classList.add(vehicleType);

    // Reset all wheel elements
    for (let i = 0; i < wheelNames.length; i++) {
        const wheelEl = document.getElementById(`wheel-${i}`);
        if (!wheelEl) continue;
        wheelEl.classList.add('wheel-box');
        wheelEl.classList.remove('tyre-hidden', 'flashing-popped');
        wheelEl.style.display = '';
        wheelEl.textContent = ''; // No text
        wheelEl.style.backgroundColor = '';
        wheelEl.style.color = '';
        wheelEl.style.setProperty('--fill-color', transparent);
        wheelEl.style.setProperty('--fill-height', '100%'); // Always 100%
    }

    // Update visible wheels
    for (let i = 0; i < wheelCount; i++) {
        const wheelEl = document.getElementById(`wheel-${i}`);
        if (!wheelEl) continue;

        const percent = durability[i] !== undefined ? Math.round(durability[i]) : 100;
        const isPopped = percent <= 0;

        if (isPopped) {
            // Style popped tire (flashing red/black, no text)
            wheelEl.setAttribute('data-popped', 'true');
            wheelEl.classList.add('wheel-box', 'flashing-popped');
            wheelEl.style.display = '';
            wheelEl.textContent = '';
            wheelEl.style.backgroundColor = pureBlack;
            wheelEl.style.color = transparent;
            wheelEl.style.setProperty('--fill-color', transparent, 'important');
            wheelEl.style.setProperty('--fill-height', '100%', 'important');
        } else {
            // Style non-popped tire (full fill with color based on degradation)
            wheelEl.classList.add('wheel-box');
            wheelEl.classList.remove('flashing-popped');
            wheelEl.style.display = '';
            wheelEl.textContent = '';
            wheelEl.style.backgroundColor = '';
            wheelEl.style.color = transparent;
            wheelEl.removeAttribute('data-popped');

            // Color gradient based on percentage
            let color = '#34d399'; // Green (100-70%)
            if (percent < 70 && percent >= 30) color = '#f59e0b'; // Orange (69-30%)
            else if (percent < 30 && percent > 0) color = '#ef4444'; // Red (29-1%)
            
            wheelEl.style.setProperty('--fill-color', color);
            wheelEl.style.setProperty('--fill-height', '100%'); // Always full height
        }
    }
};

// Handle NUI messages
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    // Show or hide UI
    if (data.action === 'setVisibility') {
        if (data.data) {
            app.classList.remove('hidden');
        } else {
            app.classList.add('hidden');
            // Reset all wheels
            for (let i = 0; i < wheelNames.length; i++) {
                const wheelEl = document.getElementById(`wheel-${i}`);
                if (wheelEl) {
                    wheelEl.classList.add('wheel-box');
                    wheelEl.classList.remove('flashing-popped');
                    wheelEl.style.display = '';
                    wheelEl.textContent = '';
                    wheelEl.style.backgroundColor = '';
                    wheelEl.style.color = '';
                    wheelEl.style.setProperty('--fill-color', transparent);
                    wheelEl.style.setProperty('--fill-height', '100%');
                }
            }
        }
    }

    // Debounce tire updates
    if (data.action === 'updateTyres') {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            try {
                processUpdate(data);
            } catch (error) {
                // Silently handle errors
            }
        }, DEBOUNCE_TIME);
    }
});
