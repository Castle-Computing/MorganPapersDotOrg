// enables bootstrap popover functionality:
$(function () {
    $('[data-toggle="popover"]').popover()
})

$(function() {
    $('#searchForm').submit(function () {
        var defaultDate1 = '1915-01-01';
        var defaultDate2 = '1945-12-31';

        if($(this)[0].elements['first_date'].value === defaultDate1 && $(this)[0].elements['second_date'].value == defaultDate2){
            $(this)[0].elements['first_date'].name = $(this)[0].elements['second_date'].name = '';
        }
        
        $(this)
            .find('input[name]')
            .filter(function () {
                if(this.name.includes("exclude")) {
                    this.checked = !this.checked;
                }

                return !this.value;
            })
            .prop('name', '');
        
        $(this)
            .find('select[name]')
            .filter(function () {
                return !this.value;
            })
            .prop('name', '');
    });
});

// prevents advanced search window from closing if user clicks on it
$(function() {
    $('.dropdown-menu.keep-open').on({
        'click': (e) => { e.stopPropagation(); },
    });
})
