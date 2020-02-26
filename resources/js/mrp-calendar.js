var mrpCalendar = (function (window, document) {
    // most of the code taken from https://github.com/ingoboerner
    //https://github.com/martinantonmueller/Hermann-Bahr_Arthur-Schnitzler/blob/master/app/resources/js/calendar.js
    var datasource = "../analyze/calendar_datasource.xql";
    var calendarRootElement;
    var calendarInstance;
    var detailsRootElement;
    var detailsHeaderElement;
    var detailsTable;
    var linkWindowTarget = "mrp-details";
    var showLinkPrefix = "show.html?document=";

    var localeDateOptions = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    var maxPopoverEntryLength = 500;

    var $disabledDays = [];
    var allPopoverContainers = [];
    var allYearButtons = {};
    var dataCache = {};

    var killPopoverGracePeriodMs = 750;
    var killPopoverAfterTimeout = false;

    $(document).ready(function () {
        var startYear = getYearParameter() || 1852;

        initializeYearTable();
        selectYearButton(startYear);

        calendarRootElement = document.getElementById('calendar'); // $('#calendar');
        calendarInstance = new Calendar(
            calendarRootElement,
            {
                dataSource: loadDataForYear,
                language: 'de',
                startYear: startYear,
                minDate: new Date(1848, 0, 1),
                maxDate: new Date(1918, 11, 30),
                weekStart: 1, // week starts on monday,
                disabledDays: $disabledDays,
                style: 'custom',
                enableRangeSelection: true,

                mouseOnDay: handleEnterDay,
                mouseOutDay: handleLeaveDay,
                clickDay: openDateLink,
                customDataSourceRenderer: function (element, date, events) {
                    if (events.length === 0) {
                        element.parentElement.classList.add('no-events');
                    }
                    else if (events.length === 1) {
                        element.parentElement.classList.add('one-event');
                    }
                    else {
                        element.parentElement.classList.add('several-events');
                    }
                },
                yearChanged: function (ev) {
                    var newYear = ev.currentYear;
                    setYearParameter(newYear);
                    selectYearButton(newYear);
                }
            }
        );

        document.addEventListener('click', function (ev) {
            // Any click removes all popovers
            removeAllPopovers();
            disablePopoverKill();
        });

        $('#calendar').on('inserted.bs.popover', function (insertEvent) {
            // Add pointer enter and leave functions to all popover bubbles
            var target = insertEvent.currentTarget;
            var popoverElements = target.getElementsByClassName('popover');
            for (var i = 0; i < popoverElements.length; i++) {
                var e = popoverElements[i];
                e.addEventListener('pointerleave', function () {
                    removeAllPopovers();
                    disablePopoverKill();
                });
                e.addEventListener('pointerenter', function () {
                    disablePopoverKill();
                })
                var childElementBoxes = e.getElementsByClassName('event-tooltip-entry');
                for (var j = 0; j < childElementBoxes.length; j++) {
                    var item = childElementBoxes[j];
                    item.addEventListener('pointerenter', function () {
                        disablePopoverKill();
                    });
                }
            }
        });

        detailsRootElement = document.querySelector('#calendar-selection-details');
        detailsHeaderElement = detailsRootElement.querySelector('.card-header h3');
        calendarRootElement.addEventListener('selectRange', function (ev) {
            showDetailsForRange(ev.startDate, ev.endDate);
        });

        detailsTable = $('#calendar-details-table').DataTable({
            keepConditions: true,
            dom: 'Bfrtip',
            buttons: [
                'copy', 'excel', 'pdf'
            ],
            paging: false,
            columns: [
                {
                    "title": "Datum",
                    "type": "date",
                    render: function (data, type, row) {
                        if (type === "sort" || type === "type") {
                            return data;
                        }
                        if (data.toLocaleDateString) {
                            return data.toLocaleDateString('de', localeDateOptions);
                        }
                        else {
                            return data;
                        }
                    }
                },
                {
                    "title": "Titel / Sitzung / Tagesordnung",
                    "type": "string"
                },
                {
                    "title": "Dokument",
                    "type": "html"
                }
            ]
        });
    });

    var loadDataForYear = function (year) {
        if (year in dataCache) {
            return dataCache[year];
        }
        var fetchedData = fetch(datasource + `?year=${year}`)
            .then(result => result.json())
            .catch(reason => {
                window.console.log('Error loading calendar data:');
                window.console.log(reason);
                return [];
            })
            .then(json_data => json_data.map(convertDbObjectToCalendarObject))
            .catch(reason => []);
        dataCache[year] = fetchedData;
        return fetchedData;
    };

    var showDetailsForRange = function (startDate, endDate) {
        detailsHeaderElement.innerHTML = startDate.toLocaleDateString('de', localeDateOptions) + ' — ' +
            endDate.toLocaleDateString('de', localeDateOptions);
        detailsTable.clear();
        var events = calendarInstance.getEventsOnRange(startDate, endDate);
        if (events.length === 0) {
            detailsRootElement.classList.add('hidden');
        }
        else {
            detailsRootElement.classList.remove('hidden');
            events.forEach(ev => {
                var html_topics = eventAsDetailsTableHtml(ev);
                var fileName = getFileNameFromUrl(ev.id);
                detailsTable.row.add([
                    ev.startDate,
                    html_topics,
                    '<a href="' + ev.id + '" target="' + linkWindowTarget + '">' + fileName + '</a>'
                ]);
            });
        }
        detailsTable.draw();
    };

    var initializeYearTable = function () {
        var yearsTable = $('#years-table');
        var yearButtons = new DocumentFragment();
        for (var year = 1848; year <= 1918; year++) {
            var newYearButton = createYearCell(year);
            yearButtons.appendChild(newYearButton);
            allYearButtons[year] = newYearButton.firstChild;
        }
        yearsTable.append(yearButtons);
    };

    var selectYearButton = function (year) {
        for (var buttonYear in allYearButtons) {
            if (buttonYear == year) {
                allYearButtons[buttonYear].classList.add('selected');
            }
            else {
                allYearButtons[buttonYear].classList.remove('selected');
            }
        }
    };

    var changeYear = function (year) {
        calendarInstance.setYear(year);
    };

    var getYearParameter = function () {
        var searchParams = new window.URLSearchParams(window.location.search);
        return searchParams.get('year');
    };

    var setYearParameter = function (year) {
        var url = new window.URL(window.location);
        var searchParams = new window.URLSearchParams(url.search);
        searchParams.set('year', year);
        url.search = searchParams.toString();
        window.history.pushState(history.state, '', url.toString());
    }

    var handleEnterDay = function (ev) {
        var thisDayHasAnAssociatedPopover = (ev.events.length !== 0);
        if (thisDayHasAnAssociatedPopover) {
            removeAllPopovers();

            var popoverContent = createPopoverContent(ev);
            createAndShowNewPopover(ev.element, ev.date, popoverContent);

            disablePopoverKill();
        }
    };

    var handleLeaveDay = function (ev) {
        var thisDayHasAnAssociatedPopover = (ev.events.length !== 0);
        if (thisDayHasAnAssociatedPopover) {
            window.setTimeout(function () {
                if (killPopoverAfterTimeout) {
                    removeAllPopovers();
                }
            }, killPopoverGracePeriodMs)

            enablePopoverKill();
        }
    };

    var convertDbObjectToCalendarObject = function (eObj) {
        var j = eObj.startDate.substring(0, 4);
        var m = eObj.startDate.substring(5, 7);
        var d = eObj.startDate.substring(8, 10);
        var bothDates = new Date(j, m - 1, d);
        window.console.log(eObj);
        return {
            id: eObj.id,
            name: eObj.name,
            startDate: bothDates,
            endDate: bothDates,
            items: eObj.items
        };
    };

    var createPopoverContent = function (e) {
        if (e.events.length > 0) {
            return `<div class="event-tooltip-content">
            ${e.events
                .map(ev => `<a class="event-tooltip-entry" href="${showLinkPrefix}${ev.id}" target="${linkWindowTarget}"><h4>${ev.name}</h4><ul>${eventItemsAsListItems(ev.items)}</ul></a>`)
                .join('')
            }
            </div>`;
        }
        else {
            return null;
        }
    };

    var createAndShowNewPopover = function (dayElement, date, content) {
        var container = $(dayElement);
        var title = date.toLocaleDateString('de', localeDateOptions);
        container.popover({
            title: title,
            trigger: 'manual',
            container: calendarRootElement,
            html: true,
            delay: { 'hide': 400 },
            content: content
        });
        allPopoverContainers.push(container);
        container.popover('show');
    };

    var removeAllPopovers = function () {
        while (allPopoverContainers.length > 0) {
            var existingContainer = allPopoverContainers.pop();
            existingContainer.popover('dispose');
        }
    }

    var enablePopoverKill = function () {
        killPopoverAfterTimeout = true;
    };

    var disablePopoverKill = function () {
        killPopoverAfterTimeout = false;
    };

    var createYearCell = function (val) {
        var e = document.createElement('div');
        e.classList.add('col-xs-6');
        e.innerHTML = '<button class="yearbtn">' + val + '</button>';
        e.firstElementChild.addEventListener('click', (function (year) {
            return function () { changeYear(year); };
        })(val));
        return e;
    };

    var getFileNameFromUrl = function (url) {
        return url.split('/').pop().split('#').shift();
    };

    var openDateLink = function (e) {
        var ids = [];
        $.each(e.events, function (key, entry) {
            ids.push(entry.id)
        });
        if (e.events.length === 1) { // avoids having broken links - an else with a modal, link bubble or some other solution would be nice to have
            // window.location = ids.join()
            window.open(ids[0], target = linkWindowTarget);
        } else if (e.events.length === 0) { // no clicking on no event dates!
        } else {
            $.each(ids, function (i, val) {
                console.log(val)

            })
            // window.location = ids[1]
            window.open(ids[1], target = linkWindowTarget);
        }
    };

    var eventAsDetailsTableHtml = function (ev) {
        var base_url = ev.id;
        window.console.log(ev);
        window.console.log(base_url);
        return `<h4>${ev.name}</h4><ul>${eventItemsAsListItemLinks(ev.items, base_url)}</ul>`;
    };

    var eventItemsAsListItems = function (items, base_url) {
        if (!items.map) {
            return '';
        }
        else {
            return items
                .map(item => `<li>${item.name}</li>`)
                .join('');
        }
    };

    var eventItemsAsListItemLinks = function (items, base_url) {
        if (!items.map) {
            return '';
        }
        else {
            return items
                .map(item => `<li><a href="${showLinkPrefix}${base_url}${item.link}" target="${linkWindowTarget}">${item.name}</a></li>`)
                .join('');
        }
    };

})(window, document);
