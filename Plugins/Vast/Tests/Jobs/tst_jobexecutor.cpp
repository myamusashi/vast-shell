#include <qobject.h>
#include <qsemaphore.h>
#include <qthread.h>
#include <qtest.h>

#include <algorithm>
#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

#include "../../Jobs/JobExecutor.hpp"

namespace {

    // Posts a job that signals `sem` and reports the thread it ran on. QSemaphore is
    // default-constructed on purpose: its argument is the initial count, not a target.
    [[nodiscard]] QThread* postAndWait(vast::JobExecutor& ex, QSemaphore& sem) {
        QThread* ranOn = nullptr;
        ex.post([&sem, &ranOn] {
            ranOn = QThread::currentThread();
            sem.release();
        });
        sem.acquire();
        return ranOn;
    }

} // namespace

class TestJobExecutor : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void instanceReturnsTheSameObjectOnEveryCall();
    void threadAccessorIsStableAndNonNull();

    void postRunsTheJob();
    void jobsRunOffTheCallingThread();
    void allJobsShareOneWorkerThread();
    void jobsRunOnTheThreadReportedByThread();
    void jobsRunInPostOrder();

    void postingFromSeveralThreadsIsSafe();
    void aLargeBatchLosesNoJob();
    void aJobMayPostAnotherJobWithoutDeadlocking();
    void postReturnsBeforeTheJobCompletes();

    void anObjectMovedToTheWorkerThreadIsSeenFromAJob();
};

void TestJobExecutor::instanceReturnsTheSameObjectOnEveryCall() {
    // A second worker thread for the whole process.
    QCOMPARE(&vast::JobExecutor::instance(), &vast::JobExecutor::instance());
}

void TestJobExecutor::threadAccessorIsStableAndNonNull() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();

    QVERIFY(ex.thread() != nullptr);
    // Callers move objects onto this pointer.
    QCOMPARE(ex.thread(), ex.thread());
}

void TestJobExecutor::postRunsTheJob() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();
    QSemaphore         sem;

    QThread*           ranOn = postAndWait(ex, sem);

    QVERIFY(ranOn != nullptr);
}

void TestJobExecutor::jobsRunOffTheCallingThread() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();
    QSemaphore         sem;

    QThread*           ranOn = postAndWait(ex, sem);

    // Heavy work stays off the UI thread.
    QVERIFY2(ranOn != QThread::currentThread(), "the job ran on the posting thread");
}

void TestJobExecutor::allJobsShareOneWorkerThread() {
    vast::JobExecutor&    ex = vast::JobExecutor::instance();

    constexpr int         kJobs = 20;
    QSemaphore            sem;
    std::mutex            mutex;
    std::vector<QThread*> seen;
    seen.reserve(kJobs);

    for (int i = 0; i < kJobs; ++i) {
        ex.post([&] {
            {
                const std::lock_guard<std::mutex> guard(mutex);
                seen.push_back(QThread::currentThread());
            }
            sem.release();
        });
    }
    for (int i = 0; i < kJobs; ++i)
        sem.acquire();

    QCOMPARE(seen.size(), static_cast<std::size_t>(kJobs));

    // One worker for the whole process, never a pool.
    std::vector<QThread*> distinct;
    for (QThread* t : seen) {
        if (std::find(distinct.begin(), distinct.end(), t) == distinct.end())
            distinct.push_back(t);
    }

    QCOMPARE(distinct.size(), static_cast<std::size_t>(1));
}

void TestJobExecutor::jobsRunOnTheThreadReportedByThread() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();
    QSemaphore         sem;

    // The accessor and the execution site must be the same thread.
    QCOMPARE(postAndWait(ex, sem), ex.thread());
}

void TestJobExecutor::jobsRunInPostOrder() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();

    constexpr int      kJobs = 5;
    QSemaphore         sem;
    std::mutex         mutex;
    std::vector<int>   order;
    order.reserve(kJobs);

    for (int i = 0; i < kJobs; ++i) {
        ex.post([&, i] {
            {
                const std::lock_guard<std::mutex> guard(mutex);
                order.push_back(i);
            }
            sem.release();
        });
    }
    for (int i = 0; i < kJobs; ++i)
        sem.acquire();

    // Serialization implies order.
    QCOMPARE(order, (std::vector<int>{0, 1, 2, 3, 4}));
}

void TestJobExecutor::postingFromSeveralThreadsIsSafe() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();

    constexpr int      kPosters   = 4;
    constexpr int      kPerPoster = 10;
    constexpr int      kTotal     = kPosters * kPerPoster;
    QSemaphore         sem;
    std::atomic<int>   ran{0};

    // Guards posting from a non-UI thread.
    std::vector<std::thread> posters;
    posters.reserve(kPosters);
    for (int p = 0; p < kPosters; ++p) {
        posters.emplace_back([&] {
            for (int i = 0; i < kPerPoster; ++i)
                ex.post([&] {
                    ++ran;
                    sem.release();
                });
        });
    }
    for (std::thread& t : posters)
        t.join();

    for (int i = 0; i < kTotal; ++i)
        sem.acquire();

    QCOMPARE(ran.load(), kTotal);
}

void TestJobExecutor::aLargeBatchLosesNoJob() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();

    constexpr int      kJobs = 1000;
    QSemaphore         sem;
    std::atomic<int>   ran{0};

    for (int i = 0; i < kJobs; ++i) {
        ex.post([&] {
            ++ran;
            sem.release();
        });
    }
    for (int i = 0; i < kJobs; ++i)
        sem.acquire();

    // Catches a bounded queue or an early drop.
    QCOMPARE(ran.load(), kJobs);
}

void TestJobExecutor::aJobMayPostAnotherJobWithoutDeadlocking() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();

    QSemaphore         outer;
    QSemaphore         inner;
    std::atomic<bool>  nested{false};

    ex.post([&] {
        // Posted from the worker itself; post() only enqueues.
        ex.post([&] {
            nested = true;
            inner.release();
        });
        outer.release();
    });

    outer.acquire();
    // Bounded only as a deadlock guard.
    QVERIFY2(inner.tryAcquire(1, 5000), "a job posting another job deadlocked the worker");
    QVERIFY(nested.load());
}

void TestJobExecutor::postReturnsBeforeTheJobCompletes() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();

    QSemaphore         started;
    QSemaphore         gate;
    std::atomic<bool>  finished{false};

    ex.post([&] {
        started.release();
        gate.acquire(); // held until the test lets it go
        finished = true;
    });

    // Never blocks the calling thread; the gate makes that assertable.
    started.acquire();
    QVERIFY2(!finished.load(), "the job completed before post() returned");

    // Release the gate and drain so the worker is left idle.
    gate.release();
    QSemaphore done;
    ex.post([&done] { done.release(); });
    done.acquire();
}

void TestJobExecutor::anObjectMovedToTheWorkerThreadIsSeenFromAJob() {
    vast::JobExecutor& ex = vast::JobExecutor::instance();

    QObject            probe;
    probe.moveToThread(ex.thread());

    QSemaphore        sem;
    std::atomic<bool> sameThread{false};
    ex.post([&] {
        sameThread = (probe.thread() == QThread::currentThread());
        sem.release();
    });
    sem.acquire();

    // The pattern WaylandDataControl uses.
    QVERIFY(sameThread.load());

    // Move it back so it is not destroyed on a foreign thread.
    probe.moveToThread(QThread::currentThread());
}

QTEST_GUILESS_MAIN(TestJobExecutor)
#include "tst_jobexecutor.moc"
