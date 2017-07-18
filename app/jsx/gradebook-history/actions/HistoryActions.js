/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

export const FETCH_HISTORY_STARTED = 'FETCH_HISTORY_STARTED';
export const FETCH_HISTORY_SUCCESS = 'FETCH_HISTORY_SUCCESS';
export const FETCH_HISTORY_FAILURE = 'FETCH_HISTORY_FAILURE';

export function fetchHistoryStarted () {
  return {
    type: FETCH_HISTORY_STARTED
  };
}

export function fetchHistorySuccess (data) {
  return {
    type: FETCH_HISTORY_SUCCESS,
    payload: data
  };
}

export function fetchHistoryFailure () {
  return {
    type: FETCH_HISTORY_FAILURE
  };
}
