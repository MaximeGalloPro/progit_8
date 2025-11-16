// map.js
// Chart.js is loaded via CDN in the _map.html.erb partial

// Wait for DOM to be fully loaded before initializing map
document.addEventListener('DOMContentLoaded', function() {
    const mapElement = document.getElementById('map');
    if (!mapElement) {
        console.warn('Map element not found on this page');
        return;
    }

    // Configure Leaflet icon paths
    delete L.Icon.Default.prototype._getIconUrl;
    L.Icon.Default.mergeOptions({
        iconRetinaUrl: '/assets/marker-icon-2x.png',
        iconUrl: '/assets/marker-icon.png',
        shadowUrl: '/assets/marker-shadow.png',
    });

    window.map = L.map('map', {
        preferCanvas: false,
        renderer: L.canvas()
    }).setView([44.0556, 5.1283], 13);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19,
        minZoom: 1
    }).addTo(window.map);

    // Use ResizeObserver to handle container size changes
    const mapContainer = document.getElementById('map-container');
    if (mapContainer) {
        const resizeObserver = new ResizeObserver(() => {
            window.map.invalidateSize();
        });
        resizeObserver.observe(mapContainer);
    }

    // Initial invalidation after short delay
    setTimeout(() => {
        window.map.invalidateSize();
        console.log('Map initialized and sized');
    }, 100);
});

const map = window.map;
const points = [];
let markers = [];
let currentRoute;

const apiKey = '5b3ce3597851110001cf6248d56a72cc718348038c651734f42f7749';

// Récupérer les champs du formulaire
const coordinatesField = document.querySelector('input[name="hike[coordinates]"]');
const distanceField = document.querySelector('input[name="hike[distance_km]"]');
const elevationGainField = document.querySelector('input[name="hike[elevation_gain]"]');
const elevationLossField = document.querySelector('input[name="hike[elevation_loss]"]');
const altitudeMinField = document.querySelector('input[name="hike[altitude_min]"]');
const altitudeMaxField = document.querySelector('input[name="hike[altitude_max]"]');

const pointsInput = document.createElement('input');
pointsInput.type = 'hidden';
pointsInput.name = 'points';

async function getRoute(points) {
    if (points.length < 2) {
        console.error('Au moins deux points sont nécessaires pour calculer un itinéraire.');
        return;
    }

    const url = `https://api.openrouteservice.org/v2/directions/foot-hiking/geojson?api_key=${apiKey}`;
    const coordinates = points.map(point => [point[1], point[0]]);

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
                coordinates,
                elevation: true
            })
        });
        const data = await response.json();

        console.log("Réponse API OpenRouteService:", data);

        if (!data.features || data.features.length === 0) {
            console.error('Aucune route trouvée dans la réponse :', data);
            return;
        }

        if (currentRoute) {
            window.map.removeLayer(currentRoute);
        }

        currentRoute = L.geoJSON(data, {
            style: {color: 'blue', weight: 4}
        }).addTo(window.map);

        const bounds = currentRoute.getBounds();
        window.map.fitBounds(bounds);

        displayRouteStats(data);
    } catch (error) {
        console.error('Erreur lors de la requête API:', error);
    }
}

function displayRouteStats(data) {
    try {
        const coordinates = data.features[0].geometry.coordinates;
        const altitudes = coordinates.map(coord => coord[2]);
        const summary = data.features[0].properties.summary;

        // Distance
        const distance = summary.distance / 1000; // Conversion en km
        document.getElementById('distance').textContent = distance.toFixed(2) + ' km';
        if (distanceField) {
            distanceField.value = distance.toFixed(2);
        }

        // Calcul des dénivelés
        let elevationGain = 0;
        let elevationLoss = 0;

        for (let i = 1; i < altitudes.length; i++) {
            const diff = altitudes[i] - altitudes[i - 1];
            if (diff > 0) {
                elevationGain += diff;
            } else {
                elevationLoss -= diff;
            }
        }

        // Mise à jour des dénivelés
        const roundedElevationGain = Math.round(elevationGain);
        const roundedElevationLoss = Math.round(elevationLoss);
        document.getElementById('elevation-gain').textContent = roundedElevationGain + ' m';
        document.getElementById('elevation-loss').textContent = roundedElevationLoss + ' m';

        if (elevationGainField) {
            elevationGainField.value = roundedElevationGain;
        }
        if (elevationLossField) {
            elevationLossField.value = roundedElevationLoss;
        }

        // Mise à jour des altitudes
        if (altitudes.length > 0) {
            const minAltitude = Math.round(Math.min(...altitudes));
            const maxAltitude = Math.round(Math.max(...altitudes));

            document.getElementById('min-altitude').textContent = minAltitude + ' m';
            document.getElementById('max-altitude').textContent = maxAltitude + ' m';

            if (altitudeMinField) {
                altitudeMinField.value = minAltitude;
            }
            if (altitudeMaxField) {
                altitudeMaxField.value = maxAltitude;
            }
        }

        generateElevationChart(coordinates);
    } catch (error) {
        console.error("Erreur lors du traitement des statistiques :", error);
    }
}

function addPoint(lat, lng, label) {
    console.log("Adding point:", lat, lng, label);

    const point = [lat, lng];
    points.push(point);
    pointsInput.value = JSON.stringify(points);
    const marker = L.marker([lat, lng], {title: label}).addTo(window.map);
    markers.push(marker);
    updateCoordinatesField();

    const closeLoop = document.getElementById('closeLoopCheckbox')?.checked;
    if (points.length === 3 && closeLoop) {
        addClosingPoint();
    }

    if (points.length >= 2) {
        getRoute(points);
    }
}

function addClosingPoint() {
    if (points.length < 3) return;

    const firstPoint = points[0];
    points.push(firstPoint);
    const marker = L.marker(firstPoint, {
        title: "Point de départ (fermeture de la boucle)"
    }).addTo(window.map);
    markers.push(marker);
    updateCoordinatesField();

    getRoute(points);
}

function removeLastPoint() {
    if (points.length === 0) return;

    points.pop();
    const marker = markers.pop();
    if (marker) {
        window.map.removeLayer(marker);
    }
    updateCoordinatesField();

    if (points.length >= 2) {
        getRoute(points);
    } else if (currentRoute) {
        window.map.removeLayer(currentRoute);
    }
}

function calculateDistancesAndAltitudes(coordinates) {
    const distances = [0];
    const altitudes = coordinates.map(coord => coord[2]);

    for (let i = 1; i < coordinates.length; i++) {
        const [lon1, lat1] = coordinates[i - 1];
        const [lon2, lat2] = coordinates[i];
        const distance = haversineDistance(lat1, lon1, lat2, lon2);
        distances.push(distances[i - 1] + distance);
    }

    return {distances, altitudes};
}

function haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const toRad = x => (x * Math.PI) / 180;

    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
}

function generateElevationChart(coordinates) {
    const {distances, altitudes} = calculateDistancesAndAltitudes(coordinates);

    let elevationChart = document.getElementById('elevationChart');
    if (!elevationChart) return;

    const ctx = elevationChart.getContext('2d');
    elevationChart.style.display = "block";

    if (window.elevationChart && typeof window.elevationChart.destroy === 'function') {
        window.elevationChart.destroy();
    }

    const gradient = ctx.createLinearGradient(0, 0, 0, 400);
    gradient.addColorStop(0, "rgba(255, 0, 0, 0.7)");
    gradient.addColorStop(0.5, "rgba(255, 255, 0, 0.7)");
    gradient.addColorStop(1, "rgba(0, 255, 0, 0.7)");

    window.elevationChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: distances.map(d => `${d.toFixed(2)} km`),
            datasets: [
                {
                    label: 'Altitude (m)',
                    data: altitudes,
                    borderColor: 'rgb(255,255,255)',
                    backgroundColor: gradient,
                    borderWidth: 2,
                    tension: 0.4,
                    pointStyle: false,
                    fill: true,
                },
            ],
        },
        options: {
            responsive: true,
            plugins: {
                tooltip: {
                    intersect: false,
                    mode: 'nearest',
                    callbacks: {
                        label: function (context) {
                            const altitude = context.raw;
                            const distance = distances[context.dataIndex];
                            return `Distance: ${distance.toFixed(2)} km, Altitude: ${altitude} m`;
                        },
                    },
                },
                legend: {
                    display: false,
                },
            },
            scales: {
                x: {
                    title: {
                        display: true,
                        text: 'Distance (km)',
                        font: {
                            size: 14,
                        },
                    },
                    grid: {
                        display: false,
                    },
                },
                y: {
                    title: {
                        display: true,
                        text: 'Altitude (m)',
                        font: {
                            size: 14,
                        },
                    },
                    grid: {
                        color: 'rgba(200, 200, 200, 0.5)',
                    },
                },
            },
        },
    });
}

function updateCoordinatesField() {
    if (coordinatesField) {
        coordinatesField.value = JSON.stringify(points);
    }
}

document.getElementById('locate-user').addEventListener('click', () => {
    if (!navigator.geolocation) {
        alert("La géolocalisation n'est pas prise en charge par votre navigateur.");
        return;
    }

    navigator.geolocation.getCurrentPosition(
        (position) => {
            const { latitude, longitude } = position.coords;
            const accuracy = position.coords.accuracy;

            // Ajoutez un marqueur pour la position de l'utilisateur
            const userMarker = L.marker([latitude, longitude], {
                title: "Votre position",
                icon: L.icon({
                    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
                    iconSize: [25, 41],
                    iconAnchor: [12, 41],
                    popupAnchor: [1, -34],
                }),
            }).addTo(window.map);

            // Ajoutez un cercle pour représenter la précision
            L.circle([latitude, longitude], {
                radius: accuracy, // Précision en mètres
                color: 'blue',
                fillColor: '#3f72af',
                fillOpacity: 0.2,
            }).addTo(window.map);

            // Centrez la carte sur la position de l'utilisateur
            window.map.setView([latitude, longitude], 13);

            // Optionnel : afficher une info-bulle avec les détails
            userMarker.bindPopup(`Vous êtes ici.<br>Précision : ±${Math.round(accuracy)} m`).openPopup();
        },
        (error) => {
            console.error("Erreur de géolocalisation :", error);
            alert("Impossible de vous localiser. Vérifiez vos permissions ou réessayez.");
        }
    );
});


// Event Listeners - must wait for map to be initialized
document.addEventListener('DOMContentLoaded', function() {
    if (!window.map) return;

    window.map.on('click', function (e) {
        const {lat, lng} = e.latlng;
        addPoint(lat, lng, `Point ${points.length + 1}`);
    });
});

document.getElementById('undo')?.addEventListener('click', (e) => {
    e.preventDefault(); // Empêche la soumission du formulaire
    removeLastPoint();
});

// Chargement initial des coordonnées
document.addEventListener('coordinatesLoaded', (event) => {
    const coordinates = JSON.parse(event.detail);
    if (Array.isArray(coordinates)) {
        coordinates.forEach(coord => {
            if (Array.isArray(coord) && coord.length === 2) {
                addPoint(coord[0], coord[1], `Point ${points.length + 1}`);
            }
        });

        if (points.length >= 2) {
            getRoute(points);
        }

        if (points.length > 0) {
            const bounds = L.latLngBounds(points);
            window.map.fitBounds(bounds);
        }
    }
});

console.log("Map script loaded");