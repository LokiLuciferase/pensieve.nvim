require "pensieve.repo"

pensieve_encryption = "gocryptfs"

local dirpath = "~/testing"
Repo.open(dirpath)
Repo.init(dirpath)
rv = Repo.isOpen(dirpath)
print(rv)
Repo.close(dirpath)
rv = Repo.isOpen(dirpath)
print(rv)

