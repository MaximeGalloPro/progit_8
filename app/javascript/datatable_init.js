// Initialisation globale de DataTables
document.addEventListener('DOMContentLoaded', function() {
    const tables = document.querySelectorAll('[data-datatable]');

    if (typeof DataTable !== 'undefined') {
        tables.forEach(table => {
            new DataTable(table, {
                language: {
                    url: '//cdn.datatables.net/plug-ins/2.1.8/i18n/fr-FR.json'
                },
                order: [[8, 'desc']], // Tri par défaut sur la colonne "Dernière date"
                pageLength: 25,
                columnDefs: [
                    { orderable: false, targets: -1 } // Désactive le tri sur la dernière colonne (Actions)
                ]
            });
        });
    }
});
