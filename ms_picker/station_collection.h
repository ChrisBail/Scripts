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

#ifndef STATION_COLLECTION_H
#define STATION_COLLECTION_H

class StationCollection {
public:
  StationCollection() {}
  StationCollection(StationTrace stationTrace);
  virtual ~StationCollection() {}

  void addTrace(StationTrace stationTrace);
  bool preparePickerFuncInfo(PPPickerFuncInfo *pickerFuncInfoPtr, const char *activeComponent);

  std::string stationCode;
  std::list<StationTrace> stationTraces;
};

#endif // !STATION_COLLECTION_H
