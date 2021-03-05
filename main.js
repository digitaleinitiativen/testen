let config = {
	base_url: 'https://thingproxy.freeboard.io/fetch/https://vorarlbergtestet.lwz-vorarlberg.at',
	locations_path: '/GesundheitRegister/Covid/GetCovidTestLocationMassTest?betriebe=0',
	dates_path: '/GesundheitRegister/Covid/GetCovidTestDatesMassTest?ort='
};

let domLocations = document.getElementById('locations');
let domDates = document.getElementById('dates');

function destructDate(date) {
	let reg = /(\d\d)\.(\d\d)\.(\d\d\d\d) (\d\d):(\d\d) - (\d\d):(\d\d) [^:]*: (\d+)/gmi;
	let a = reg.exec(date);
	return {
		day: a[1],
		month: a[2],
		year: a[3],
		startHour: a[4],
		startMinute: a[5],
		endHour: a[6],
		endMinute: a[7],
		slots: a[8]		
	};
}

function destructLocation(location) {
	let reg = /^([^\ ]*) ([^,]*)(, (.*))?/gmi;
	let a = reg.exec(location);
	if(a == null) { // testbus
		return {
			place: location,
			city: "?",
			street: "?"
		}
	}
	return {
		place: a[2],
		city: a[1],
		street: a[4] ? a[4] : "" // landestheater
	};
}

function fillLocations(locations) {
	for(var i = 0; i < locations.length; i++) {
		let node = document.createElement('li');
		node.appendChild(document.createTextNode(destructLocation(locations[i].value).city));
		node.dataset.key = locations[i].key;
		node.dataset.value = locations[i].value;
		node.onclick = function() {
			loadDates(this.dataset.key);
		}
		domLocations.appendChild(node);
	}
}

function loadLocations(locations) {
	fetch(config.base_url + config.locations_path).then(function(response) {
		return response.json();
	}).then(function(locations) {
		fillLocations(locations);
	});	
}

function fillDates(dates) {
	domDates.innerHTML = '';
	for(var i = 0; i < dates.length; i++) {
		let node = document.createElement('li');
		node.appendChild(document.createTextNode(dates[i].value));
		node.dataset.key = dates[i].key;
		node.dataset.value = dates[i].value;
		node.onclick = function() {
		}
		domDates.appendChild(node);
	}	
}

function loadDates(location) {
	console.log(config.base_url + encodeURI(config.dates_path + encodeURI(location.replaceAll(" ", "+"))));

	fetch(config.base_url + config.dates_path, {
	    "headers": {
	        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
	    },
	    "body": "ort=" + encodeURI(location.replaceAll(" ", "+")),
	    "method": "POST",
	    "mode": "cors"
	}).then(function(response) {
		return response.json();
	}).then(function(dates) {
		fillDates(dates);
	});
}

window.onload = function(){
	loadLocations();
}
