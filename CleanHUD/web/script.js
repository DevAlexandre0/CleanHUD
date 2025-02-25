function updateSeatbeltStatus(isOn) {
    const seatbeltElement = document.getElementById("seatbelt");
    const seatbeltIcon = seatbeltElement.querySelector('i');

    if (isOn) {
        seatbeltElement.classList.add("on");
        seatbeltElement.classList.remove("off");
        seatbeltIcon.classList.replace('fa-user', 'fa-user-slash'); // Seatbelt on
    } else {
        seatbeltElement.classList.add("off");
        seatbeltElement.classList.remove("on");
        seatbeltIcon.classList.replace('fa-user-slash', 'fa-user'); // Seatbelt off
    }
}

window.addEventListener('message', function (event) {
    const data = event.data;
   
    if (data.action === 'updateHud') {
        updateHud(data);
    } else if (data.action === 'updateVehicleHud') {
        updateVehicleHud(data);
    } else if (data.action === 'updateStatusHud') {
        updateStatusHud(data);
    } else if (data.action === 'switchMode') {
        modeSwitch(data);
    } else if (data.action === 'toggleSeatBelt') {
        toggleSeatbelt(data.seatbelt);
    } else if (data.action === 'toggleHud') {
        toggleHud(data.state);
    } else if (data.action === 'showVehicleHud' || data.action === 'hideVehicleHud') {
        showHideVehicleHud(data.action);
    }
});

function updateHud(data) {
    document.getElementById('id-text').innerText = ` ID: ${data.playerId}`;
    document.getElementById('money-text').innerText = ` $${data.money}`;
    document.getElementById('bank-text').innerText = ` $${data.bankMoney}`;
    document.getElementById('job-text').innerText = `${data.job} - ${data.jobGrade}`;
}

function updateVehicleHud(data) {
    document.getElementById('fuel-text').innerText = `${Math.floor(data.fuel)}%`;
    document.getElementById('speed-text').innerText = `${Math.floor(data.speed).toString().padStart(3, '0')}`;
    document.getElementById('rpm-text').innerText = `RPM: ${Math.floor(data.rpm)}`;

    // Transmission (Gear)
    const transmissionText = document.getElementById('transmission-text');
    transmissionText.innerText = ` ${data.gear}`;
    transmissionText.classList.remove('neutral', 'reverse');

    if (data.gear === "N") {
        transmissionText.classList.add('neutral');
    } else if (data.gear === "R") {
        transmissionText.classList.add('reverse');
    }

    // RPM Bar
    updateRpmBar(data.rpm);
    updateHealthBars(data.bodyHealth, data.engineHealth);
}

function updateStatusHud(data) {
    document.getElementById('health-text').innerText = `${data.health}`;
    document.getElementById('hunger-text').innerText = `${data.hunger}`;
    document.getElementById('thirst-text').innerText = `${data.thirst}`;

    // Show armor only if it exists
    document.getElementById('armor').style.display = data.armor ? 'flex' : 'none';
    document.getElementById('armor-text').innerText = data.armor || '';

    // Show stamina only if it's below 100
    document.getElementById('stamina').style.display = data.stamina < 100 ? 'flex' : 'none';
    document.getElementById('stamina-text').innerText = data.stamina || '';

    // Show oxygen only if it's below 100
    document.getElementById('oxygen').style.display = data.oxygen < 100 ? 'flex' : 'none';
    document.getElementById('oxygen-text').innerText = data.oxygen || '';

    // Show stress only if it exists
    document.getElementById('stress').style.display = data.stress ? 'flex' : 'none';
    document.getElementById('stress-text').innerText = data.stress || '';
}

function modeSwitch(data) {
    const gearContainer = document.querySelector('.gear-container');
    const gearModeText = document.getElementById('gearMode-text');

    if (data.gearMode) {
        gearContainer.style.display = 'flex';  // Show container
        gearModeText.innerText = `Mode: ${data.gearMode}`;
    } else {
        gearContainer.style.display = 'none';  // Hide container
    }
}

function toggleSeatbelt(isOn) {
    updateSeatbeltStatus(isOn);
}

function toggleHud(state) {
    const displayState = state ? 'flex' : 'none';
    document.querySelector('.hud-container').style.display = displayState;
    document.querySelector('.status-container').style.display = displayState;
    document.querySelector('.gear-container').style.display = displayState;
}

function showHideVehicleHud(action) {
    const showHud = action === 'showVehicleHud' ? 'flex' : 'none';
    const showDisplay = action === 'showVehicleHud' ? 'block' : 'none';

    document.querySelector('.fuel-container').style.display = showHud;
    document.querySelector('.transmission-container').style.display = showHud;
    document.querySelector('.speed-display').style.display = showDisplay;
    document.querySelector('.rpm-bar-container').style.display = showDisplay;
    document.querySelector('.vehicle-icons').style.display = showHud;
    document.querySelector('.rpm-container').style.display = showHud;
}

function updateRpmBar(rpm) {
    let rpmPercent = (rpm / 10000) * 100;
    let rpmBar = document.getElementById('rpm-bar');
    rpmBar.style.width = rpmPercent + '%';
    rpmBar.style.background = rpmPercent > 90 ? 'red' : rpmPercent > 70 ? 'yellow' : 'white';
}

function updateHealthBars(bodyHealth, engineHealth) {
    function getColor(value) {
        return value > 75 ? 'white' : value > 40 ? 'yellow' : 'red';
    }

    let bodyBar = document.getElementById('body-bar');
    bodyBar.style.height = Math.min((bodyHealth / 100) * 30, 30) + 'px';
    bodyBar.style.background = getColor(bodyHealth);

    let engineBar = document.getElementById('engine-bar');
    engineBar.style.height = Math.min((engineHealth / 100) * 30, 30) + 'px';
    engineBar.style.background = getColor(engineHealth);
}