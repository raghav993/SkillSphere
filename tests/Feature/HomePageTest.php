<?php

// test('example', function () {
//     $response = $this->get('/');

//     $response->assertStatus(200);
// });

test('homepage loads successfully', function () {
    $response = $this->get('/');
    $response->assertStatus(200);
});
