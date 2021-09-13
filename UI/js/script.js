
var app = new Vue({
    el: '#app',
    data: {
        showFuel: true,
        showEngine: true,
        showBody: true,
        vehicles: [],
        search: '',
        nearbyPlayers: []

    },
    methods: {
        focusSearchBox()
        {
            this.$refs.searchBox.focus();
        },
        close() {
            this.vehicles.forEach(vehicle => {
                this.hideTransfer(vehicle);
                this.hideSetName(vehicle);
            });
            
            // this.$refs.vehicleDetailsPanel -- Need to think about how to collapse all items at once with Vue.js, as in remove the 'show' class
            // But using jQuery here does actually work so using it for now
            $('.collapse').collapse('hide');

            this.search = '';
            $.post('https://htb_garage/close', JSON.stringify({}));
        },
        modelName(vehicle) {
            if(!vehicle.modelName || vehicle.modelName === 'NULL') {
                return vehicle.spawnName;
            }

            return vehicle.modelName;
        },
        takeOut(vehicle) {
            this.search = '';
            const requestOptions = {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({vehicle: vehicle, payForRetrieve: false})
                
            };
            fetch("https://htb_garage/takeOut", requestOptions)
                .then(response => response.json())
                .then(data => (this.postId = data.id));

            this.close(vehicle);
        },
        retrieve(vehicle) {
            this.search = '';
            const requestOptions = {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({vehicle: vehicle, payForRetrieve: true})
                
            };
            fetch("https://htb_garage/takeOut", requestOptions)
                .then(response => response.json())
                .then(data => (this.postId = data.id));

            this.close(vehicle);
        },
        setGpsMarker(vehicle) {
            const requestOptions = {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({vehicle: vehicle})
                
            };
            fetch("https://htb_garage/setGpsMarker", requestOptions)
                .then(response => response.json())
                .then(data => (this.postId = data.id));
        },
        setVehicleName(vehicle) {
            const requestOptions = {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({plate: vehicle.plate, newName: vehicle.tempNickName})
                
            };
            fetch("https://htb_garage/setVehicleName", requestOptions)
                .then(response => response.json())
                .then(data => {
                    (this.postId = data.id);
                    vehicle.displayName = vehicle.tempNickName;
                    this.hideSetName(vehicle);
                });
        },
        fetchNearbyPlayers() {
            const requestOptions = {
                method: "POST",
                headers: { "Content-Type": "application/json" }                
            };
            fetch("https://htb_garage/fetchNearbyPlayers", requestOptions)
                .then(response => response.json())
                .then(data => (this.postId = data.id));
        },
        transferVehicleOwnership(vehicle) {
            const requestOptions = {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    plate: vehicle.plate,
                    newOwner: vehicle.selectedNewOwner
                })
                
            };
            fetch("https://htb_garage/transferOwnership", requestOptions)
                .then(response => response.json())
                .then(data => (this.postId = data.id));

            this.hideTransfer(vehicle);

        },
        showTransfer(vehicle) {
            this.hideSetName(vehicle);
            vehicle.transferOwnership = true;
        },
        hideTransfer(vehicle) {
            if(vehicle != undefined) {
                vehicle.transferOwnership = false;
            }
            vehicle.selectedNewOwner = '';
        },
        showSetName(vehicle) {
            this.hideTransfer(vehicle);
            vehicle.showSetName = true;
        },
        hideSetName(vehicle) {
            vehicle.showSetName = false;
            vehicle.tempNickName = '';
        }

    },
    computed: {
        filteredVehicles() {
            return this.vehicles.filter(item => {
                if(this.search === '') return item;
                return item.plate.toLowerCase().indexOf(this.search.toLowerCase()) > -1
                    || item.spawnName !== undefined && item.spawnName.toLowerCase().indexOf(this.search.toLowerCase()) > -1
                    || item.modelName !== undefined && item.modelName.toLowerCase().indexOf(this.search.toLowerCase()) > -1
                    || item.displayName !== undefined && item.displayName.toLowerCase().indexOf(this.search.toLowerCase()) > -1
                    || item.vehiclename !== undefined && item.vehiclename.toLowerCase().indexOf(this.search.toLowerCase()) > -1
            })
        },

    }

});


document.onreadystatechange = () => {
    if (document.readyState === "complete") {
        window.addEventListener('message', (event) => {
            if (event.data.type === 'enable') {
                document.body.style.display = event.data.isVisible ? "block" : "none";
                app.focusSearchBox();
                app.showFuel = event.data.showFuel;
                app.showEngine = event.data.showEngine;
                app.showBody = event.data.showBody;
            } else if (event.data.type === 'setVehicles') {
                app.vehicles = JSON.parse(event.data.vehicles);
            } else if (event.data.type === 'setNearbyPlayersList') {
                app.nearbyPlayers = JSON.parse(event.data.nearbyPlayers);
            } else if (event.data.type === 'transferComplete') {
                app.hideTransfer();
            }
        });
    }
};

/* Handle escape key press to close the menu */
document.onkeyup = function (data) {
    // console.log(JSON.stringify(data));
    if (data.which == 27) {
        app.close();
        
    }
};

