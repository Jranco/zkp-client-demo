//
//  AlertQueueScheduler.swift
//  WeSpot
//
//  Created by Thomas Segkoulis on 30.12.23.
//

import Foundation
import SwiftUI

protocol AlertDisplaying: ObservableObject {
	var queueFired: Queue<AlertBanner.Model> { get }
	init(numOfConcurrentAlerts: Int, alertDuration: Double)
	func schedule(alert: AlertBanner.Model) throws
	func pause()
	func resume(shouldClearScheduled: Bool, after: Double?)
	func clear()
}

extension AlertDisplaying {
	func resume() {
		resume(shouldClearScheduled: true)
	}
	
	func resume(shouldClearScheduled: Bool) {
		resume(shouldClearScheduled: shouldClearScheduled, after: nil)
	}
	
	func dismissAll() {
		resume(shouldClearScheduled: true, after: 0)
	}
}

class AlertQueueScheduler: AlertDisplaying {

	// MARK: - Public properties

	/// A queue containing the alerts that are fired.
	@Published public private(set) var queueFired: Queue<AlertBanner.Model>

	// MARK: - Private properties

	/// A queue containing the alerts to be scheduled.
	private var queueScheduled: Queue<AlertBanner.Model>
	/// Number of concurrently visible alert views.
	private var numOfConcurrentAlerts: Int
	/// Duration of a single alert in seconds.
	private var alertDuration: Double
	/// A tmp storage of all active timers managing scheduled alerts dismiss.
	private var activeTimers: Queue<Timer>

	// MARK: - Initialization

	required public init(
		numOfConcurrentAlerts: Int,
		alertDuration: Double
	) {
		self.queueScheduled = .init(elements: [])
		self.queueFired = .init(elements: [])
		self.activeTimers = .init(elements: [])
		self.numOfConcurrentAlerts = numOfConcurrentAlerts
		self.alertDuration = alertDuration
	}

	public convenience init() {
		self.init(numOfConcurrentAlerts: 3, alertDuration: 2)
	}

	// MARK: - Public methods

	func schedule(alert: AlertBanner.Model) throws {
		queueScheduled.enqueue(alert)
		guard queueFired.count < numOfConcurrentAlerts else {
			throw AlertQueueSchedulerError.reachedMaxConcurrentAlerts
		}
		try fireNextAlertIfNeeded()
	}

	func pause() {
		activeTimers.list.forEach { timer in
			timer.invalidate()
		}
		activeTimers.dequeueAll()
	}
	
	func resume(shouldClearScheduled: Bool, after: Double? = nil) {
		for _ in 0..<queueFired.count {
			addNewActiveTimer(duration: after ?? (alertDuration/4))
		}
		if shouldClearScheduled {
			queueScheduled.dequeueAll()
		}
	}

	func clear() {
		queueScheduled.dequeueAll()
		queueFired.dequeueAll()
	}

	// MARK: - Private methods

	private func fireNextAlertIfNeeded() throws {
		guard let nextAlert = queueScheduled.dequeue() else {
			throw AlertQueueSchedulerError.emptyScheduledAlerts
		}
		withAnimation {
			queueFired.enqueue(nextAlert)
		}
		addNewActiveTimer(duration: alertDuration)
	}

	@objc 
	private func dismissAlert() {
		activeTimers.dequeue()
		_ = withAnimation {
			queueFired.dequeue()
		}
		try? self.fireNextAlertIfNeeded()
	}
	
	private func addNewActiveTimer(duration: Double) {
		let timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(dismissAlert), userInfo: nil, repeats: false)
		activeTimers.enqueue(timer)
	}
}

// MARK: - Error namespace

enum AlertQueueSchedulerError: Error {
	case reachedMaxConcurrentAlerts
	case emptyScheduledAlerts
}
