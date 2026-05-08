#!/venv/bin/python3

import os
import sys

os.environ['CURL_CA_BUNDLE'] = ''
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

import duckdb
from ibis import _
import vastdb
import vastdb.config

def parse_endpoints(s):
    endpoints = s.split(',')
    if len(endpoints) == 1:
        endpoints = endpoints * 8
    return endpoints

ENDPOINTS = parse_endpoints(os.environ['VASTDB_ENDPOINTS'])
AWS_ACCESS_KEY_ID = os.environ['VASTDB_ACCESS_KEY']
AWS_SECRET_ACCESS_KEY = os.environ['VASTDB_SECRET_KEY']

def main(search_path):
    dconn = duckdb.connect()

    vconn = vastdb.connect(
        endpoint=ENDPOINTS[0],
        access=AWS_ACCESS_KEY_ID,
        secret=AWS_SECRET_ACCESS_KEY,
        ssl_verify=False)

    with vconn.transaction() as tx:
        table = tx.catalog()
        qconfig = vastdb.config.QueryConfig(
            data_endpoints=ENDPOINTS,
            num_sub_splits=10,
            rows_per_split=4000000)
        columns = ['uid', 'size', 'used']
        predicate = (_.search_path == search_path)
        batches = table.select(config=qconfig, columns=columns, predicate=predicate)
        dconn.execute("""
            copy (
                select
                    uid,
                    count(*) as num_inodes,
                    sum(size) as sum_size,
                    sum(used) as sum_used
                from batches
                group by uid
                having sum_used > 0
                order by sum_used desc
            ) to '/dev/stdout' (format csv, header)
        """)

if __name__ == '__main__':
    main(sys.argv[1])

