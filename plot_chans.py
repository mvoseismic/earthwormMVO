#!/usr/bin/env python
# plot_chans.py
#
# Creates a multichannel plot using obspy
#
# R.C. Stewart, 2021-09-27
#
import os
import sys
import glob
import re
import obspy
from datetime import datetime, date, timedelta
from dateutil import parser as dparser
from dateutil.rrule import rrule, DAILY
from obspy.clients.earthworm import Client
from obspy.core import UTCDateTime, Stream


def main():

    #ipWws = "172.17.102.60"
    ipWws = "172.17.102.13"

    portWws = 16022

    minutesPlot = 4

    dirOut = "."

    # Constants

    dirnameSeparator = "/"
    clientTimeout = 20


    # Define wave server
    client = Client( ipWws, portWws, clientTimeout )

    # Time span wanted
    rightNow = datetime.utcnow()
#    datimEnd = UTCDateTime( rightNow.year, rightNow.month, rightNow.day, rightNow.hour, rightNow.minute, rightNow.second )
    datimEnd = UTCDateTime( 2021, 9, 25, 3, 14, 24 )
    datimBeg = datimEnd - minutesPlot*60


    filePlot = dirnameSeparator.join( [ dirOut, 'fig-4chan.png' ] )

    sta = "MSS1"
    net = "MV"
    cha = "SHZ"
    loc = "--"

#    print( 'Trying to get data from waveserver' )
    st = client.get_waveforms( net, sta, loc, cha, datimBeg, datimEnd)
    st += client.get_waveforms( net, 'MBLY', '00', 'HHZ', datimBeg, datimEnd)
    st += client.get_waveforms( net, 'MBHA', '--', 'SHZ', datimBeg, datimEnd)
    st += client.get_waveforms( net, 'MBRV', '--', 'BHZ', datimBeg, datimEnd)
#    print( st )


    # Create plot
    st.plot( equal_scale=0, outfile=filePlot, color='blue', linewidth=0.5 )


if __name__ == "__main__":
    main()


