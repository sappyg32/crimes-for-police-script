const noiseContainer = document.getElementById('noise-container');
const noiseBar = document.getElementById('noise-bar');
const noiseThreshold = document.getElementById('noise-threshold');
const noiseStatus = document.getElementById('noise-status').querySelector('.status-text');
const noiseIcon = document.querySelector('.noise-icon');
const noiseUI = document.querySelector('.noise-ui');
const crouchHint = document.getElementById('crouch-hint');
const hintKey = document.querySelector('.hint-key');

let currentNoise = 0;
let maxNoise = 100;
let thresholdLevel = 80;

// Listen for messages from the game
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'showUI':
            showUI(data.position, data.showHint);
            break;
            
        case 'hideUI':
            hideUI();
            break;
            
        case 'updateNoise':
            updateNoiseLevel(data.noise, data.max, data.warning);
            break;
            
        case 'setCrouching':
            setCrouching(data.crouching);
            break;
    }
});

function showUI(position, showHint) {
    // Remove all position classes
    noiseContainer.classList.remove('top-left', 'top-right', 'bottom-left', 'bottom-right');
    
    // Add the correct position class
    noiseContainer.classList.add(position || 'bottom-right');
    
    // Show/hide crouch hint
    if (showHint) {
        crouchHint.classList.remove('hidden');
    } else {
        crouchHint.classList.add('hidden');
    }
    
    // Show the container
    noiseContainer.classList.remove('hidden');
    
    // Reset state
    currentNoise = 0;
    updateNoiseLevel(0, 100, false);
}

function hideUI() {
    noiseContainer.classList.add('hidden');
    
    // Reset UI state
    noiseUI.classList.remove('warning', 'danger');
    noiseStatus.classList.remove('warning', 'danger');
    noiseIcon.classList.remove('warning');
}

function updateNoiseLevel(noise, max, warning) {
    currentNoise = noise;
    maxNoise = max || 100;
    
    // Calculate percentage
    const percentage = Math.min((noise / maxNoise) * 100, 100);
    
    // Update bar width
    noiseBar.style.width = percentage + '%';
    
    // Update bar color based on thresholds (solid color)
    if (percentage >= 66) {
        noiseBar.style.backgroundColor = '#f44336'; // Red
    } else if (percentage >= 33) {
        noiseBar.style.backgroundColor = '#ffeb3b'; // Yellow
    } else {
        noiseBar.style.backgroundColor = '#00c853'; // Green
    }
    
    // Update status text and styling based on noise level
    if (percentage >= 100) {
        noiseStatus.textContent = 'CAUGHT!';
        noiseStatus.classList.add('danger');
        noiseStatus.classList.remove('warning');
        noiseUI.classList.add('danger');
        noiseUI.classList.remove('warning');
        noiseIcon.textContent = '🔊';
        noiseIcon.classList.add('warning');
    } else if (percentage >= thresholdLevel) {
        noiseStatus.textContent = 'Owner Waking!';
        noiseStatus.classList.add('warning');
        noiseStatus.classList.remove('danger');
        noiseUI.classList.add('warning');
        noiseUI.classList.remove('danger');
        noiseIcon.textContent = '🔉';
        noiseIcon.classList.add('warning');
    } else if (percentage >= 50) {
        noiseStatus.textContent = 'Getting Loud';
        noiseStatus.classList.remove('warning', 'danger');
        noiseUI.classList.remove('warning', 'danger');
        noiseIcon.textContent = '🔈';
        noiseIcon.classList.remove('warning');
    } else if (percentage >= 25) {
        noiseStatus.textContent = 'Be Careful';
        noiseStatus.classList.remove('warning', 'danger');
        noiseUI.classList.remove('warning', 'danger');
        noiseIcon.textContent = '🔈';
        noiseIcon.classList.remove('warning');
    } else {
        noiseStatus.textContent = 'Stay Quiet';
        noiseStatus.classList.remove('warning', 'danger');
        noiseUI.classList.remove('warning', 'danger');
        noiseIcon.textContent = '🔇';
        noiseIcon.classList.remove('warning');
    }
}

function setCrouching(isCrouching) {
    if (isCrouching) {
        hintKey.classList.add('active');
    } else {
        hintKey.classList.remove('active');
    }
}
