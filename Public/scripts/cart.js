$(function() { 
    var currentCart = Cookies.getJSON("cart");
    $('.cartButton').each(function() {
        var components = $(this).attr("pid").split(":", 2)
        if (components.length !== 2) { return }
        var prefix = components[0]
        var value = components[1]
        if (currentCart && currentCart[prefix] && 
         (currentCart[prefix].endsWith(value) || currentCart[prefix].includes(value + ","))) {
            $(this).removeClass("text-success").addClass("text-danger")
            $(this).html("Remove Letter from Cart")
        }
    })
    
});

$('.cartFeature').click(function(e) {
    var currentCart = Cookies.getJSON("cart");
    var queryString = "?"
    for(key in currentCart) {
        if(!currentCart[key].length) { continue }

        if (queryString.length > 1) {
            queryString += "&"
        }

        queryString += key + "=" + currentCart[key]
    }

    if(queryString.length === 1) { return }
    var baseURL = $(this).attr("url")
    window.location.href = baseURL + queryString
});

$('.cartButton').click(function(e) {
    e.stopPropagation();
    var removing = false;
    var pid = $(this).attr("pid")
    var components = pid.split(":", 2)
    if (components.length !== 2) { return }
    var prefix = components[0]
    var value = components[1]

    currentCart = Cookies.getJSON("cart");
    if (currentCart) {
        Cookies.remove("cart")
    } else {
        currentCart = {}
    }

    if (currentCart && currentCart[prefix]) {
        if (!currentCart[prefix].endsWith(value) && !currentCart[prefix].includes(value + ",")) {
            currentCart[prefix] += "," + value
        } else {
            removing = true;
            currentCart[prefix] = currentCart[prefix].split(",").filter(e => e !== value).join(",") 
            if (currentCart[prefix] === "") {
                delete currentCart[prefix]
            }
        }
    } else {
        currentCart[prefix] = value
    }

    Cookies.set("cart", JSON.stringify(currentCart), { expires: 365 })

    if (removing) {
        if($(".cartButton[pid='" + pid + "']").hasClass("cartPage")){
            $(".cartButton[pid='" + pid + "']").parent().parent().parent().parent().remove()
        } else {
            $(".cartButton[pid='" + pid + "']").removeClass("text-danger").addClass("text-success")
            $(".cartButton[pid='" + pid + "']").html("Add Letter to Cart")
        }
        
    } else {
        $(".cartButton[pid='" + pid + "']").removeClass("text-success").addClass("text-danger")
        $(".cartButton[pid='" + pid + "']").html("Remove Letter from Cart")
    }
}); 