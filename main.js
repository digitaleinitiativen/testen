let config = {
	base_url: '', // 'https://vorarlbergtestet.lwz-vorarlberg.at',
	locations_path: 'moc-locations.json', //'/GesundheitRegister/Covid/GetCovidTestLocationMassTest?betriebe=0'
	dates_path: 'moc-dates.json'
};

let domLocations = document.getElementById('locations');
let domDates = document.getElementById('dates');

function fillLocations(locations) {
	for(var i = 0; i < locations.length; i++) {
		let node = document.createElement('li');
		node.appendChild(document.createTextNode(locations[i].value));
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
			console.log(this.dataset.key);
		}
		domDates.appendChild(node);
	}	
}

function loadDates(location) {
	fetch(config.base_url + config.dates_path).then(function(response) {
		return response.json();
	}).then(function(dates) {
		fillDates(dates);
	});
}

window.onload = function(){
	loadLocations();
}
