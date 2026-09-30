// Loads the schema file for the database, nothing more.

if num-dbs eq 0 then
    message "No database available!".
else do:
    message "Loading database schema file 'thrasher.df'".
    run prodict/load_df.p ("thrasher.df").
end.

finally:
    return string(0). // Return a friendly PCT/Ant response.
end finally.