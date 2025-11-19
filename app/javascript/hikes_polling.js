// Polling pour mettre à jour l'état des hikes en cours de mise à jour
let pollingInterval = null;
const POLL_INTERVAL = 3000; // 3 secondes

function getUpdatingHikeIds() {
    const buttons = document.querySelectorAll('[data-hike-updating="true"]');
    return Array.from(buttons).map(btn => btn.dataset.hikeId);
}

async function checkStatus(hikeIds) {
    if (hikeIds.length === 0) return { updating: [], completed: [] };

    try {
        const response = await fetch(`/hikes/check_updating_status?ids=${hikeIds.join(',')}`);
        return await response.json();
    } catch (error) {
        console.error('Error checking hike status:', error);
        return { updating: hikeIds, completed: [] };
    }
}

export function startPolling() {
    if (pollingInterval) return;

    const hikeIds = getUpdatingHikeIds();
    if (hikeIds.length === 0) return;

    console.log('Starting polling for hikes:', hikeIds);

    pollingInterval = setInterval(async () => {
        const currentIds = getUpdatingHikeIds();

        if (currentIds.length === 0) {
            stopPolling();
            return;
        }

        const status = await checkStatus(currentIds);

        if (status.completed.length > 0) {
            console.log('Hikes completed:', status.completed);
            // Recharger la page pour voir les mises à jour
            window.location.reload();
        }
    }, POLL_INTERVAL);
}

export function stopPolling() {
    if (pollingInterval) {
        console.log('Stopping polling');
        clearInterval(pollingInterval);
        pollingInterval = null;
    }
}

// Auto-start au chargement
document.addEventListener('DOMContentLoaded', startPolling);
