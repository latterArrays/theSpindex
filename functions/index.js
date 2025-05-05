/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const axios = require("axios");
const functions = require('firebase-functions');

exports.proxyDiscogs = onRequest(async (request, response) => {
    const { endpoint, ...queryParams } = request.query;

    if (!endpoint) {
        console.error("Missing 'endpoint' query parameter.");
        response.set("Access-Control-Allow-Origin", "*"); // Add CORS header for errors
        return response.status(400).send("Missing 'endpoint' query parameter.");
    }

    try {
        const url = `https://api.discogs.com/${endpoint}`;
        const discogsKey = process.env.DISCOGS_KEY;
        const discogsSecret = process.env.DISCOGS_SECRET;
        const userAgent = "TheSpindex/1.0 +https://thespindex-d6b69.web.app/"; // Replace with your own user agent

        console.log("Making request to Discogs API:");
        console.log(`URL: ${url}`);
        console.log(`Query Parameters: ${JSON.stringify(queryParams)}`);
        console.log(`Headers: Authorization: Discogs key=${discogsKey}, secret=${discogsSecret}, User-Agent: ${userAgent}`);

        const apiResponse = await axios.get(url, {
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Discogs key=${discogsKey}, secret=${discogsSecret}`,
                "User-Agent": userAgent,
            },
            params: queryParams,
        });

        console.log("Discogs API response received:");
        console.log(`Status: ${apiResponse.status}`);
        console.log(`Data: ${JSON.stringify(apiResponse.data)}`);

        // Add CORS headers to the response
        response.set("Access-Control-Allow-Origin", "*");
        response.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.set("Access-Control-Allow-Headers", "Content-Type");

        response.status(apiResponse.status).json(apiResponse.data);
    } catch (error) {
        console.error("Error proxying request:", error.message);
        if (error.response) {
            console.error("Discogs API Error Response:");
            console.error(`Status: ${error.response.status}`);
            console.error(`Data: ${JSON.stringify(error.response.data)}`);
        }

        // Add CORS headers to the error response
        response.set("Access-Control-Allow-Origin", "*");
        response.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.set("Access-Control-Allow-Headers", "Content-Type");
        
        response.status(500).send("Error proxying request.");
    }
});