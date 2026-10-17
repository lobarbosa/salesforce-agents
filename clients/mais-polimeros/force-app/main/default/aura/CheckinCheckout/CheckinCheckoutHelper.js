({
    carregaTipoCheckin: function (onResponse) {
        setTimeout(function () {
            var serverResponse = {
                selectedTipoId: 'Negociação',
                tipos: [
                    { id: 'Negociação', label: 'Negociação', selected: true },
                    { id: 'Prospecção', label: 'Prospecção' },
                    { id: 'Visita Técnica', label: 'Visita Técnica' }
                ]
            };

            onResponse.call(null, serverResponse);
        }, 500);
    }

    // carregaTipoContato: function (onResponse) {
    //     setTimeout(function () {
    //         var serverResponse = {
    //             selectedTipoId: 'Contato',
    //             tipos: [
    //                 { id: 'Contato', label: 'Contato', selected: true },
    //                 { id: 'Lead', label: 'Lead' }
    //             ]
    //         };

    //         onResponse.call(null, serverResponse);
    //     }, 500);
    // }

})