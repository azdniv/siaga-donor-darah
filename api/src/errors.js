'use strict';

/** Error dengan status HTTP. Bila dilempar di dalam transaksi, transaksi otomatis di-rollback. */
class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

module.exports = { HttpError };
