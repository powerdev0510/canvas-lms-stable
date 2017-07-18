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

import {
  FETCH_HISTORY_STARTED,
  FETCH_HISTORY_SUCCESS,
  FETCH_HISTORY_FAILURE,
  fetchHistoryStarted,
  fetchHistorySuccess,
  fetchHistoryFailure
} from 'jsx/gradebook-history/actions/HistoryActions';

QUnit.module('HistoryActions');

test('fetchHistoryStarted creates an action with type FETCH_HISTORY_STARTED', function () {
  const expectedValue = {
    type: FETCH_HISTORY_STARTED
  };
  deepEqual(fetchHistoryStarted(), expectedValue);
});

test('fetchHistorySuccess creates an action with type FETCH_HISTORY_SUCCESS and data', function () {
  const data = { 1: 'some data' };
  const expectedValue = {
    type: FETCH_HISTORY_SUCCESS,
    payload: data
  };
  deepEqual(fetchHistorySuccess(data), expectedValue);
});

test('fetchHistoryFailure creates an action with type FETCH_HISTORY_FAILURE', function () {
  const expectedValue = {
    type: FETCH_HISTORY_FAILURE
  };
  deepEqual(fetchHistoryFailure(), expectedValue);
});
