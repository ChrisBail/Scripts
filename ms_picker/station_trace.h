/*
 * This file is part of ms_picker.
 *
 * Copyright (C) 2009 Andy Heath, Stuart Nippress & Andreas Rietbrock,
 *                    University of Liverpool
 *
 * This work was funded as part of the NERIES (JRA5) project.
 * Additional funding for Nippress from NERC research grant NE/C000315/1
 *
 * ms_picker is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * ms_picker is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with ms_picker.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef STATION_TRACE_H
#define STATION_TRACE_H

class StationTrace {
public:
  class StationRecord {
  public:
    StationRecord() {}
    StationRecord(hptime_t _startTime, char sampleType, int nitems, void *items, double _dt);
    virtual ~StationRecord() {}

    bool operator <(const StationRecord& sr) { return startTime < sr.startTime; }

    hptime_t startTime;
    std::list<double> data;
    double dt;
  };

  StationTrace() {}
  StationTrace(std::string _networkCode, std::string _stationCode, std::string _channelCode)
    : networkCode(_networkCode), stationCode(_stationCode), channelCode(_channelCode)
    {
      filename = networkCode + std::string("_") + stationCode + std::string("_") + channelCode + std::string(".txt");
    }
  virtual ~StationTrace() {}
  bool operator ==(const StationTrace& st) { return filename == st.filename; }

  void addData(hptime_t _startTime, char sampleType, int nitems, void *items, double _dt);
  bool concatenateRecordsIntoPDAS(PPfData* ppfDataPtr);
  
  std::string networkCode;
  std::string stationCode;
  std::string channelCode;
  std::string filename;
  std::list<StationRecord> records;
};

#endif // !STATION_TRACE_H

