'use strict';

exports.handler = function (event, context, callback) {
    var response = {
        statusCode: 200,
        headers: {
            'Content-Type': 'text/html; charset=utf-8',
        },
        body: "<p>Hello world!</p>",
    };
    callback(null, response);
};

// Essa é uma função lambda simples, para uso com API Gateway, que retorna uma mensagem "Hello world!", essa resposta está na estrutura do objeto da forma que o API Gateway espera.