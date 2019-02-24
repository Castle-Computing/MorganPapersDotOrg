$(function() { 
    currentCart = Cookies.getJSON("cart");
    $('.cartButton').each(function() {
        var components = $(this).attr("pid").split(":", 2)
        if (components.length !== 2) { return }
        var prefix = components[0]
        var value = components[1]
        if (currentCart && currentCart[prefix] && 
         (currentCart[prefix].endsWith(value) || currentCart[prefix].includes(value + ","))) {
            if($(this).hasClass("btn-outline-success")) {
                $(this).removeClass("btn-outline-success").addClass("btn-outline-danger")
            }
            $(this).html("Remove Letter from Cart")
        }
    })
    
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
            $(".cartButton.btn-outline-danger[pid='" + pid + "']").removeClass("btn-outline-danger").addClass("btn-outline-success")
            $(".cartButton[pid='" + pid + "']").html("Add Letter to Cart")
        }
        
    } else {
        $(".cartButton.btn-outline-success[pid='" + pid + "']").removeClass("btn-outline-success").addClass("btn-outline-danger")
        $(".cartButton[pid='" + pid + "']").html("Remove Letter from Cart")
    }
}); 