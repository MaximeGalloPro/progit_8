const fetchButton = document.getElementById('fetch_openrunner_data');
const spinner = document.getElementById('loading_spinner');

if (fetchButton) {
    fetchButton.addEventListener('click', async function () {
        const openrunnerRef = document.getElementById('openrunner_ref_input').value;

        if (!openrunnerRef) {
            alert('Veuillez entrer une référence OpenRunner');
            return;
        }

        // UI feedback
        spinner.classList.remove('d-none');
        fetchButton.disabled = true;
        console.log("Making request to:", `/hikes/fetch_openrunner_details?openrunner_ref=${openrunnerRef}`);

        try {
            const response = await fetch(`/hikes/fetch_openrunner_details?openrunner_ref=${openrunnerRef}`);
            console.log("Response received:", response);
            const data = await response.json();
            console.log("Data received:", data);

            if (data.error) {
                console.error("Error from server:", data.error);
                alert('Erreur lors de la récupération des données: ' + data.error);
                return;
            }

            // Mise à jour des champs du formulaire
            Object.entries(data).forEach(([key, value]) => {
                const input = document.querySelector(`#hike_${key}`);
                if (input) {
                    console.log(`Setting ${key} to ${value}`);
                    input.value = value;
                } else {
                    console.log(`Input not found for ${key}`);
                }
            });

        } catch (error) {
            console.error("Fetch error:", error);
            alert('Erreur lors de la récupération des données');
        } finally {
            // Reset UI
            spinner.classList.add('d-none');
            fetchButton.disabled = false;
        }
    });
} else {
    console.warn("Button not found");
}

const difficultyInput = document.querySelector('input[type="range"]');
// const difficultyValue = document.getElementById('difficultyValue');

// const updateDifficultyLabel = (value) => {
//     const labels = {
//         1: 'Très facile',
//         2: 'Facile',
//         3: 'Moyen',
//         4: 'Difficile',
//         5: 'Très difficile'
//     };
//     difficultyValue.textContent = labels[value];
// };

difficultyInput.addEventListener('input', (e) => {
    updateDifficultyLabel(e.target.value);
});

// Initialiser la valeur au chargement
// updateDifficultyLabel(difficultyInput.value);
