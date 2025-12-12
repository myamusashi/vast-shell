.pragma library

function sendRequest(url, callback) {
    let request = new XMLHttpRequest();
    request.onreadystatechange = function () {
        if (request.readyState === XMLHttpRequest.DONE) {
            let response = {
                "status": request.status,
                "headers": request.getAllResponseHeaders(),
                "contentType": request.responseType,
                "content": request.response
            };
            callback(response);
        }
    };
    request.open("GET", url);
    request.send();
}

function fetchData(url, onSuccess, onError) {
    sendRequest(url, function (response) {
        if (response.status === 200) {
            try {
                const json = JSON.parse(response.content);
                onSuccess(json);
            } catch (e) {
                if (onError) {
                    onError("Failed to parse JSON", e);
                } else {
                    console.error("Failed to parse JSON:", e);
                }
            }
        } else {
            if (onError) {
                onError("Request failed", response.status);
            } else {
                console.error("Request failed with status:", response.status);
            }
        }
    });
}
