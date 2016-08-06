page = require('webpage').create()
system = require('system')
env = system.env;

console.log("phantomjs: Running tests at #{system.env.ROOT_URL} using test-in-console and coverage")

page.onConsoleMessage = (message) ->
  console.log(message)

page.open(system.env.ROOT_URL)

page.onError = (msg, trace) ->

  mochaIsRunning = page.evaluate ->
    return window.mochaIsRunning

  # Mocha will handle and report the uncaught errors for us
  if mochaIsRunning
    return

  console.log("phantomjs: #{msg}")

  trace.forEach((item) ->
    console.log("    #{item.file}: #{item.line}")
  )
  phantom.exit(6)

page.onCallback = (data) ->
  ## Callback when sending and saving coverage
  if data && data.err
      console.log("coverage error: #{data.err}")
      phantom.exit(7)
  else
     phantom.exit(0)


checkingStatus = setInterval ->
    done = page.evaluate ->
        return TEST_STATUS.DONE if TEST_STATUS?
        return DONE if DONE?
        return false

    if done
        failures = page.evaluate ->
            return TEST_STATUS.FAILURES if TEST_STATUS?
            return FAILURES if FAILURES?
            return false
        if failures
            phantom.exit(2)
        else
            ## tests are ok, we remove the timer that checks if test are done
            clearInterval checkingStatus
            try
                ## Execute coverage actions
                importCoverageDump = env.COVERAGE_IN_COVERAGE == "true"
                exportCoverageDump = env.COVERAGE_OUT_COVERAGE == "true"
                exportLcovonly = env.COVERAGE_OUT_LCOVONLY == "true"
                exportHtml = env.COVERAGE_OUT_HTML == "true"
                exportJson = env.COVERAGE_OUT_JSON == "true"
                exportTeamcity = env.COVERAGE_OUT_TEAMCITY == "true"
                exportJsonSummary = env.COVERAGE_OUT_JSON_SUMMARY == "true"
                page.evaluate runCoverage, importCoverageDump, exportCoverageDump, exportLcovonly, exportHtml, exportJson, exportTeamcity, exportJsonSummary
            catch error
                window.callPhantom
                    err: error
, 500

runCoverage = (importCoverageDump, exportCoverageDump, exportLcovonly, exportHtml, exportJson, exportTeamcity, exportJsonSummary) ->
    ## Define coverage services
    window.assertCoverageEnabled = (onSuccess) ->
        if ! Package || ! Package['meteor'] || ! Package['meteor']['Meteor'] || ! Package['meteor']['Meteor'].sendCoverage || ! Package['meteor']['Meteor'].exportCoverage || ! Package['meteor']['Meteor'].importCoverage
            window.callPhantom
                err: "Coverage package missing or not correclty launched"
        else
            onSuccess();
    window.saveClientSideCoverage = (onSuccess) ->
        Package['meteor']['Meteor'].sendCoverage (stats,err) ->
            console.log("Tests are ok! Meteor-coverage is saving client side coverage to the server. Client js files saved ", JSON.stringify(stats))
            if err
                 window.callPhantom
                    err: "Failed to send client coverage"
            else
                onSuccess();

    window.exportLcovonlyReport = (onSuccess) ->
        Package['meteor']['Meteor'].exportCoverage 'lcovonly', (err) ->
            if err
                window.callPhantom
                    err: "Failed to save lcovonly coverage"
            else
                onSuccess();

    window.exportCoverageDump = (onSuccess) ->
        Package['meteor']['Meteor'].exportCoverage 'coverage', (err) ->
            if err
                window.callPhantom
                    err: "Failed to save coverage dump"
            else
                onSuccess();

    window.exportHtmlReport = (onSuccess) ->
        Package['meteor']['Meteor'].exportCoverage 'html', (err) ->
            if err
                window.callPhantom
                    err: "Failed to save html report"
            else
                onSuccess();

    window.exportJsonReport = (onSuccess) ->
        Package['meteor']['Meteor'].exportCoverage 'json', (err) ->
            if err
                window.callPhantom
                    err: "Failed to save json report"
            else
                onSuccess();

    window.exportTeamcityReport = (onSuccess) ->
        Package['meteor']['Meteor'].exportCoverage 'teamcity', (err) ->
            if err
                window.callPhantom
                    err: "Failed to save teamcity report"
            else
                onSuccess();

    window.exportJsonSummary = (onSuccess) ->
        Package['meteor']['Meteor'].exportCoverage 'json_summary', (err) ->
            if err
                window.callPhantom
                    err: "Failed to save coverage dump"
            else
                onSuccess();

    window.importCoverageDump = (onSuccess) ->
        Package['meteor']['Meteor'].importCoverage (err) ->
            if err
                window.callPhantom
                    err: "Failed to import coverage dump"
            else
                onSuccess();

    ## Execute desired tasks
    window.assertCoverageEnabled(->
        window.saveClientSideCoverage(->
            stepFurtherImportCoverageDump = ->
                stepFurtherExportCoverageDump = ->
                    stepFurtherExportLcovOnly = ->
                        stepFurtherExportHtml = ->
                            stepFurtherExportJson = ->
                                stepFurtherExportTeamcity = ->
                                    if exportJsonSummary
                                        window.exportJsonSummary(->
                                            window.callPhantom
                                                success: "true"
                                        );
                                    else
                                        window.callPhantom
                                            success: "true"
                                if exportTeamcity
                                    window.exportTeamcityReport stepFurtherExportTeamcity
                                else
                                    stepFurtherExportTeamcity();
                            if exportJson
                                window.exportJsonReport stepFurtherExportJson
                            else
                                stepFurtherExportJson();

                        if exportHtml
                            window.exportHtmlReport stepFurtherExportHtml
                        else
                            stepFurtherExportHtml();

                    if exportLcovonly
                        window.exportLcovonlyReport stepFurtherExportLcovOnly
                    else
                        stepFurtherExportLcovOnly();

                if exportCoverageDump
                    window.exportCoverageDump stepFurtherExportCoverageDump
                else
                    stepFurtherExportCoverageDump()

            if importCoverageDump
                window.importCoverageDump stepFurtherImportCoverageDump
            else
                stepFurtherImportCoverageDump()
        );
    );
